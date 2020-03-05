# Gaming Awards ksqlDB demo

## Setup

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

![Confluent Control Center](https://github.com/ugol/gaming-awards/blob/master/images/c3.png)

## Use Case

The architecture of this demo is to show a use case where a customer has a stream of Gaming events flowing into Kafka, and a couple of tables in a relational DB with some details on customers and the games they are playing. Using Debezium, we will "import" the tables in Kafka and then with ksqlDB we will build interesting streaming applications to try to get some value from the raw stream data.

IMAGE

## Architecture

As you can see, there are 8 different images running. 

Core kafka:
- zookeeper (gaming-zookeeper)
- kafka broker (gaming-kafka)
- schema registry (gaming-schema-registry)

Connect & ksqlDB:
- connect server (gaming-connect)
- ksqlDB server (gaming-ksql-server)
- ksqlDB command line (gaming-ksql-cli)

Then there is also:
- confluent control center (gaming-control-center), the graphical user interface to monitor and manage the cluster
- a mysql instance (gaming-mysql)
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
- ```confluent-hub-components``` contains two connectors, namely datagen and debezium.
-- [Datagen](https://github.com/confluentinc/kafka-connect-datagen) is a special kind of connector which is useful to create traffic.
-- [Debezium](https://debezium.io/) is a CDC project which is great to easily import relational DB tables into kafka.
- The ```data``` directory contains some SQL scripts to prepare the ```CUSTOMERS``` and ```GAMES``` tables.
- The ```datagen``` directory contains an avro file which is by the connector to create *random* raw gaming events
- The ```docker-compose.yml``` is the file containing the definitions of all the docker images involved and the glue - mostly environment variables - to connect all of them together 

## Let's look at the MySQL database

Now open up a new terminal and have a look now at the Mysql tables. You can do that with the following commands

```
docker exec -it gaming-mysql mysql -uroot -pconfluent
use demo;
select * from CUSTOMERS;
select * from GAMES;
```

## Let's finally stream!

Now you can exit from mysql command line and connect to the ksqlDB CLI:

```
docker exec -it gaming-ksql-cli ksql http://ksql-server:8088
```

You should see something like the following

```                  
                  ===========================================
                  =        _  __ _____  ____  _             =
                  =       | |/ // ____|/ __ \| |            =
                  =       | ' /| (___ | |  | | |            =
                  =       |  <  \___ \| |  | | |            =
                  =       | . \ ____) | |__| | |____        =
                  =       |_|\_\_____/ \___\_\______|       =
                  =                                         =
                  =  Streaming SQL Engine for Apache Kafka® =
                  ===========================================

Copyright 2017-2019 Confluent Inc.

CLI v5.4.0, Server v5.4.0 located at http://ksql-server:8088

Having trouble? Type 'help' (case-insensitive) for a rundown of how things work!

ksql> 
```

You are now connected to the ksqlDB CLI (Command Line Interface). This way of interacting with ksqlDB is the so called interactive mode. In production systems, you may want to use the headless mode, which is another [deployment mode](https://docs.confluent.io/current/ksql/docs/concepts/ksql-architecture.html#ksql-deployment-modes
) and it's more suited to production environments.  

Note: Ksql is just the "old" name, but eventually all the Ksql labels will be renamed as ksqlDB, which is the new kid on the block: in this demo we will use the new name, but they are the same.

From the ksqlDB command line, you can easily look at the topics and the streams that with the ```show``` command.

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

describe connector source_dbz_mysql;
```

It is possible to print directly from the topics. Note that topics are case-sensitive so need we to single-quote the topic names and correctly case them whenever we have to reference them. In contrast, all ksqlDB constructs are case-insensitive, as it is in most DBs.

```
print 'gaming.demo.CUSTOMERS-cdc';
print 'gaming.demo.GAMES-cdc';
print 'gaming.demo.CUSTOMERS-cdc' limit 10;
```

Let's now create a customer stream, getting data from the topic that debezium created. For now, we won't transform the data but we will just get what's in the Debezium CDC-created topic.

```
CREATE STREAM customers_cdc WITH (kafka_topic='gaming.demo.CUSTOMERS-cdc', value_format='avro');
```
Because we aren’t yet generating any new changes in the MySQL database, if you want to run some test queries against this new stream to see the actual data, you will first need to run
```
set 'auto.offset.reset'='earliest';
```
to force your subsequent queries to read the underlying topic from the earliest message offset or you won’t see any output. This is exactly the same as the "earliest / latest" parameter you use with a normal consumer. (Each new query creates a new consumer group).

Let's now finally try a query!

```
select * from CUSTOMERS_CDC emit changes;
```

Note the ```EMIT CHANGES``` construct: this is a syntax change from the past, which it's a way to distinguish between [push](https://docs.ksqldb.io/en/latest/concepts/queries/push/)  and [pull](https://docs.ksqldb.io/en/latest/concepts/queries/pull) queries

The output is not very nice and a bit confusing, unfortunately: that's because the topic created from Debezium is a complex structure containing a list of rows:

- metadata about the db transaction which caused the row to change
- a 'before' struct of the changed row, containing "old" data. This will be empty in case of an 'insert'.
- an 'after' struct of the changed row containing "new" data. This will be empty in case of a 'delete').

So let's now "flatten" the stream in a more readable one:

```
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

And look at the data, which shiuld be much readable now.

```
select * from CUSTOMERS_FLAT EMIT CHANGES;
```

Better,no?

Let's do the same for the GAMES topic

```
CREATE STREAM games_cdc WITH (kafka_topic='gaming.demo.GAMES-cdc', value_format='avro');

create stream games_flat with (partitions=1) as
select after->id as id,
       after->name as name
from games_cdc
partition by id;
```

We can now create two tables, starting from the topics implicitly created by the streams:

```
CREATE TABLE customers WITH(kafka_topic='CUSTOMERS_FLAT', value_format='avro', key='ID');
CREATE TABLE games WITH(kafka_topic='GAMES_FLAT', value_format='avro', key='ID');

SELECT * from customers EMIT CHANGES;
```

If we now update the data in he Mysql tables, which you can easily do opening a new terminal, you should be able to see how the data in the ksqlDB table changes almost immediately, thanks to the CDC: 

```
docker exec -it gaming-mysql mysql -uroot -pconfluent
update CUSTOMERS set first_name = 'Master', last_name='Test' where id = 1;
```

## Ok, lets do real and useful stuff now!

Let's create a stream from the games_events topic first. That's the topic with raw data coming from the datagen connector.

```
create stream games_events with (kafka_topic='games_events', value_format='avro');
```

We can now create an enriched stream with the customers details, doing a [left join](https://docs.confluent.io/current/ksql/docs/developer-guide/join-streams-and-tables.html) between the stream itself and the Customers table

```
create stream enriched_games_events as select g.amount, c.first_name, c.last_name from games_events g left join customers c on g.customer_id = c.id;

select * from ENRICHED_GAMES_EVENTS emit changes;
```

Let's now apply the same concepts and create a table with the total wins for each and every customer:

```
create table win_totals as select customer_id, sum(amount) from games_events group by customer_id emit changes;
create table win_totals_enriched as select c.first_name, c.last_name, t.ksql_col_1 from win_totals t left join customers c on t.customer_id = c.id;

select * from win_totals_enriched emit changes;
```

TODO: windows aggregates
