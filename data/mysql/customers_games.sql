CREATE DATABASE if not exists demo;
#GRANT ALL PRIVILEGES ON demo.* TO 'mysqluser'@'%';

use demo;

\! echo creating customers table...
drop table if exists CUSTOMERS;
create table CUSTOMERS (
        id INT PRIMARY KEY,
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(50),
        gender VARCHAR(50),
	status VARCHAR(8),
        create_ts timestamp DEFAULT CURRENT_TIMESTAMP ,
        update_ts timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

\! echo Inserting customers...
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (1, 'Ugo', 'Landini', 'ugo@confluent.io', 'Male', 'uranium');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (2, 'Diego', 'Daniele', 'ddaniele@confluent.io', 'Male', 'platinum');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (3, 'Paolo', 'Castagna', 'paolo@confluent.io', 'Male', 'bronze');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (4, 'Joaquim', 'Phoenix', 'joker@phoenix.com', 'Male', 'platinum');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (5, 'Charles', 'Bronson', 'bronson@charles.us', 'Male', 'platinum');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (6, 'Angelina', 'Jolie', 'ajolie@reddit.com', 'Female', 'platinum');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (7, 'Sophia', 'Loren', 'sophia@laciociara.com', 'Female', 'uranium');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (8, 'Sergio', 'Leone', 'sergio_leone@west.com', 'Male', 'silver');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (9, 'Anthony', 'Hopkins', 'hopkins@liver.com', 'Male', 'silver');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (10, 'Claudia', 'Cardinale', 'claudia@west.com', 'Female', 'silver');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (11, 'Clint', 'Eastwood', 'clint@stranger.com', 'Male', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (12, 'Frances', 'McDormand', 'frances@movies.com', 'Female', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (13, 'Margot', 'Robbie', 'margot_robbie@hollywood.us', 'Female', 'platinum');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (14, 'Meryl', 'Streep', 'meryl@oscar.us', 'Female', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (15, 'Bob', 'De Niro', 'bob@actorstudio.edu', 'Male', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (16, 'Al', 'Pacino', 'al@actorstudio.com', 'Male', 'bronze');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (17, 'Olivia', 'Colman', 'olivia@thequeen.uk', 'Female', 'bronze');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (18, 'Francis Ford', 'Coppola', 'coppola@cinema.com', 'Male', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (19, 'Leonardo', 'Di Caprio', 'leo@wolf.com', 'Male', 'gold');
insert into CUSTOMERS (id, first_name, last_name, email, gender, status) values (20, 'Cate', 'Blanchett', 'cate@white.gov', 'Female', 'gold');

\! echo creating games table...
drop table if exists GAMES;
create table GAMES (
        id INT PRIMARY KEY,
        name VARCHAR(50),
        notes VARCHAR(50),
        create_ts timestamp DEFAULT CURRENT_TIMESTAMP ,
        update_ts timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

\! echo Inserting games...
insert into GAMES (id, name, notes) values (1, 'Rolling Thunder', 'Slot Machine theme cabinet');
insert into GAMES (id, name, notes) values (2, 'Money Eater', '');
insert into GAMES (id, name, notes) values (3, 'Betman', '');
insert into GAMES (id, name, notes) values (4, 'World Wide Trap', '');
insert into GAMES (id, name, notes) values (5, 'Cash Cash', '');
