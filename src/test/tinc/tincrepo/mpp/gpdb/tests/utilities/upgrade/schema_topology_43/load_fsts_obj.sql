-- Create tablespaces
   CREATE tablespace ts_sch1 filespace cdbfast_fs_sch1;
   CREATE tablespace ts_sch2 filespace cdbfast_fs_sch1;
   CREATE tablespace ts_sch3 filespace cdbfast_fs_sch1;
   CREATE tablespace ts_sch4 filespace cdbfast_fs_sch1;
   CREATE tablespace ts_sch5 filespace cdbfast_fs_sch1;
   CREATE tablespace ts_sch6 filespace cdbfast_fs_sch1;


-- Create Roles   
   CREATE ROLE sch_fsts_db_owner1;

-- Create Database
   CREATE DATABASE sch_fsts_db_name1 WITH OWNER = sch_fsts_db_owner1 TEMPLATE =template1 ENCODING='utf8'  CONNECTION LIMIT= 2 TABLESPACE = ts_sch1;

-- Alter Database   
   ALTER DATABASE sch_fsts_db_name1 WITH  CONNECTION LIMIT 3;
-- Alter Database to new tablespace is not supported  
   ALTER DATABASE sch_fsts_db_name1 set TABLESPACE = ts_sch3;


   set default_tablespace='ts_sch3';
--Create Table   
  CREATE TABLE sch_fsts_test_part1 (id int, name text,rank int, year date, gender  char(1)) tablespace ts_sch3 DISTRIBUTED BY (id, gender, year)
      partition by list (gender) subpartition by range (year) subpartition template (start (date '2001-01-01'))
      (values ('M'),values ('F'));

-- Add default partition
   alter table sch_fsts_test_part1 add default partition default_part;

-- Drop Default Partition
   alter table sch_fsts_test_part1 DROP default partition if exists;

-- Vacuum analyze the table
   vacuum analyze sch_fsts_test_part1 ;

-- Alter the table to new table space 
   alter table sch_fsts_test_part1 set tablespace ts_sch2;

-- Insert few records into the table
   insert into sch_fsts_test_part1 values (1,'ann',1,'2001-01-01','F');
   insert into sch_fsts_test_part1 values (2,'ben',2,'2002-01-01','M');
   insert into sch_fsts_test_part1 values (3,'leni',3,'2003-01-01','F');
   insert into sch_fsts_test_part1 values (4,'sam',4,'2003-01-01','M');

-- Alter the table set distributed by 
   Alter table sch_fsts_test_part1 set with ( reorganize='true') distributed randomly;

-- select from the Table
   select * from sch_fsts_test_part1;

-- Vacuum analyze the table
   vacuum analyze sch_fsts_test_part1 ;

   vacuum analyze ;
~                     

-- Btree Index
   CREATE TABLE fsts_heap_btree(text_col text,bigint_col bigint,char_vary_col character varying(30),numeric_col numeric,int_col int4,float_col float4,int_array_col int[],drop_col numeric,before_rename_col int4,change_datatype_col numeric,a_ts_without timestamp without time zone,b_ts_with timestamp with time zone,date_column date) tablespace ts_sch1 DISTRIBUTED RANDOMLY ;

   CREATE INDEX fsts_heap_idx1 ON fsts_heap_btree (numeric_col) tablespace ts_sch5;

   insert into fsts_heap_btree values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
   insert into fsts_heap_btree values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
   insert into fsts_heap_btree values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
   insert into fsts_heap_btree select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

-- Alter to new tablespace
   select count(*) from fsts_heap_btree;

-- Alter the Index to new table space
   ALTER INDEX fsts_heap_idx1 set tablespace ts_sch3;

-- Insert few records into the table
   insert into fsts_heap_btree values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
   insert into fsts_heap_btree values ('2_zero', 1, '2_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');

-- Reindex 
   reindex index fsts_heap_idx1;

-- select from the Table
   select count(*) from fsts_heap_btree;

-- Vacuum analyze the table
   vacuum analyze fsts_heap_btree;
