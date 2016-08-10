create database db_test_bed;
\c db_test_bed
CREATE USER db_user13;
CREATE DATABASE db_schema_test owner db_user13;
\c  db_schema_test
CREATE SCHEMA db_schema5 AUTHORIZATION db_user13 ;
CREATE SCHEMA AUTHORIZATION db_user13;

ALTER SCHEMA db_user13 RENAME TO db_schema6;
ALTER SCHEMA  db_schema6 OWNER TO db_user13;
