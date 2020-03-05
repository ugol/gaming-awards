Open up a terminal session, navigate to the gaming-awards directory

```
cd gaming-awards
```

and start the containers:

```
docker-compose up
```

Open up a second terminal window and check that all the services are up:

```
docker-compose ps
```
you should get something like

```
ugol@streammo:~/Documents/src/ksql-gaming-awards$ docker-compose ps
         Name                      Command                State                     Ports              
-------------------------------------------------------------------------------------------------------
gaming-connect           /bin/bash -c                  Up (healthy)   0.0.0.0:8083->8083/tcp, 9092/tcp 
                         # Now launch ...                                                              
gaming-control-center    /etc/confluent/docker/run     Up             0.0.0.0:9021->9021/tcp           
gaming-kafka             /etc/confluent/docker/run     Up             0.0.0.0:9092->9092/tcp           
gaming-ksql-cli          /bin/sh                       Up                                              
gaming-ksql-server       /etc/confluent/docker/run     Up             0.0.0.0:8088->8088/tcp           
gaming-mysql             docker-entrypoint.sh mysqld   Up             0.0.0.0:3306->3306/tcp, 33060/tcp
gaming-schema-registry   /etc/confluent/docker/run     Up             0.0.0.0:8081->8081/tcp           
gaming-zookeeper         /etc/confluent/docker/run     Up             2181/tcp, 2888/tcp, 3888/tcp  
```

For reference, if you get strange errors or images that cannot go up correctly, it's probably because a previous docker run has left some lingering artifacts in temporary directories: to ensure everything is cleaned up and ready to start again, here's a way to be sure that everything has been cleaned up correctly and that you're starting with a fresh and crispy image 

```
docker-compose down --remove-orphans --volumes
```

So, now that everything is up, let's be sure that's *really* up. If the ```docker-compose up``` command is still logging like hell, it's probably not really ready. You can try to connect to http://localhost:9021. If you see a nice green healthy cluster, you're ready.

<IMAGE>

As you can see, there are 8 different images running. 

Core kafka:
- zookeeper (gaming-zookeeper)
- kafka broker (gaming-kafka)
- schema registry (gaming-schema-registry)

Connect & KSQL:
- connect server (gaming-connect)
- ksql server (gaming-ksql-server)
- ksql command line (gaming-ksql-cli)

Then there is also:
- confluent control center (gaming-control-center), the graphical user interface to monitor and manage the cluster
- a mysql instance (gaming-mysql)

The architecture of this demo is to show a use case where a customer has a stream of Gaming events flowing into Kafka, and a couple of tables in a relational DB with some details on customers and the games they are playing. Using Debezium, we will "import" the tables in Kafka and then with KSQL we will build interesting streaming applications to try to get some value from the raw stream data.

<IMAGE>

Let's have a look at the project directory structure

```
ugol@streammo:~/Documents/src/ksql-gaming-awards$ tree -L 3
.
├── confluent-hub-components
│   ├── confluentinc-kafka-connect-datagen
│   │   ├── assets
│   │   ├── doc
│   │   ├── etc
│   │   ├── lib
│   │   └── manifest.json
│   └── debezium-debezium-connector-mysql
│       ├── assets
│       ├── doc
│       ├── lib
│       └── manifest.json
├── data
│   └── mysql
│       ├── customers_games.sql
│       └── setup_dbz_user.sql
├── datagen
│   └── games_service.avro
├── docker-compose.yml
└── README.md
```
```confluent-hub-components``` contains two connectors, datagen and debezium. Datagen https://github.com/confluentinc/kafka-connect-datagen is a special kind of connector which is useful to create traffic. Debezium <https://debezium.io/> is a CDC project which is great to easily import relational DB tables into kafka.
The ```data``` directory contains some SQL scripts to prepare the ```CUSTOMERS``` and ```GAMES``` tables.
The ```datagen``` directory contains an avro file which is by a datagen connector to create the raw gaming events
The ```docker-compose.yml``` is the file containing the definitions of all the docker images involved and the glue - mostly environment variables - to connect all of them together 

Now open up a new terminal and have a look now at the Mysql tables. You can do that with the following commands

```
docker exec -it gaming-mysql mysql -uroot -pconfluent
use demo;
select * from CUSTOMERS;
select * from GAMES;
```

Now exit from mysql and connect to KSQL CLI:

```
docker exec -it gaming-ksql-cli ksql http://ksql-server:8088
```
You can easily look at the topics and the streams that with the ```show``` command.

```
show topics;
show streams;
```

Create a debezium connector instance, directly from the ksqlDB cli:

```
CREATE SOURCE CONNECTOR source_dbz_mysql WITH (
          'connector.class' = 'io.debezium.connector.mysql.MySqlConnector',
          'database.hostname' = 'mysql',
          'database.port' = '3306',
          'database.user' = 'debezium',
          'database.password' = 'dbzpass',
          'database.server.id' = '42',
          'snapshot.mode' = 'when_needed',
          'database.allowPublicKeyRetrieval' = 'true',
          'database.server.name' = 'gaming',
          'table.whitelist' = 'demo.*',
          'database.history.kafka.bootstrap.servers' = 'kafka:29092',
          'database.history.kafka.topic' = 'dbhistory.demo' ,
          'include.schema.changes' = 'true',
          'transforms' =  'addTopicSuffix',
          'transforms.addTopicSuffix.type' = 'org.apache.kafka.connect.transforms.RegexRouter',
          'transforms.addTopicSuffix.regex' = '(.*)',
          'transforms.addTopicSuffix.replacement' = '$1-cdc'
);
```
Have a look at the running connectors and the new topics that debezium created:

```
show connectors;
show topics;
```


```
set 'auto.offset.reset'='earliest';
print 'gaming.demo.CUSTOMERS-cdc';
print 'gaming.demo.GAMES-cdc';
```

Let's now create a customer stream, getting data from the topic that debezium created:

```
CREATE STREAM customers_cdc WITH (kafka_topic='gaming.demo.CUSTOMERS-cdc', value_format='avro');
```

```
select * from CUSTOMERS_CDC emit changes;

create stream customers_flat with (partitions=1) as
select after->id as id,
       after->first_name as first_name,
       after->last_name as last_name,
       after->email as email,
       after->gender as gender,
       after->status as status
from customers_cdc
partition by id;
```

```
select * from CUSTOMERS_FLAT EMIT CHANGES;
```

```
CREATE STREAM games_cdc WITH (kafka_topic='gaming.demo.GAMES-cdc', value_format='avro');
```


```
create stream games_flat with (partitions=1) as
select after->id as id,
       after->name as name
from games_cdc
partition by id;
```

```
CREATE TABLE customers WITH(kafka_topic='CUSTOMERS_FLAT', value_format='avro', key='ID');
CREATE TABLE games WITH(kafka_topic='GAMES_FLAT', value_format='avro', key='ID');
```



```
docker exec -it gaming-mysql mysql -uroot -pconfluent
update CUSTOMERS set first_name = 'Master', last_name='Test' where id = 1;
```

```
create stream games_events with (kafka_topic='games_events', value_format='avro');
create stream enriched_games_events as select g.amount, c.first_name, c.last_name from games_events g left join customers c on g.customer_id = c.id;
```
```
select * from ENRICHED_GAMES_EVENTS emit changes;
```

```
create table win_totals as select customer_id, sum(amount) from games_events group by customer_id emit changes;
create table win_totals_enriched as select c.first_name, c.last_name, t.ksql_col_1 from win_totals t left join customers c on t.customer_id = c.id;
```
