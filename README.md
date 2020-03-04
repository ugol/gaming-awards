```

docker-compose down --remove-orphans --volumes
docker-compose up
docker-compose ps

docker exec -it gaming-mysql mysql -uroot -pconfluent
use demo;
select * from CUSTOMERS;
select * from GAMES;

docker exec -it gaming-ksql-cli ksql http://ksql-server:8088
show topics;
show streams;

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

show connectors;
show topics;
set 'auto.offset.reset'='earliest';
print 'gaming.demo.CUSTOMERS-cdc';
print 'gaming.demo.GAMES-cdc';
CREATE STREAM customers_cdc WITH (kafka_topic='gaming.demo.CUSTOMERS-cdc', value_format='avro');
show streams;
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

select * from CUSTOMERS_FLAT EMIT CHANGES;

CREATE STREAM games_cdc WITH (kafka_topic='gaming.demo.GAMES-cdc', value_format='avro');

create stream games_flat with (partitions=1) as
select after->id as id,
       after->name as name
from games_cdc
partition by id;

CREATE TABLE customers WITH(kafka_topic='CUSTOMERS_FLAT', value_format='avro', key='ID');
CREATE TABLE games WITH(kafka_topic='GAMES_FLAT', value_format='avro', key='ID');
docker exec -it gaming-mysql mysql -uroot -pconfluent
update CUSTOMERS set first_name = 'Master', last_name='Test' where id = 1;

create stream games_events with (kafka_topic='games_events', value_format='avro');
create stream enriched_games_events as select g.amount, c.first_name, c.last_name from games_events g left join customers c on g.customer_id = c.id;

select * from ENRICHED_GAMES_EVENTS emit changes;

create table win_totals as select customer_id, sum(amount) from games_events group by customer_id emit changes;

create table win_totals_enriched as select c.first_name, c.last_name, t.ksql_col_1 from win_totals t left join customers c on t.customer_id = c.id;

```
