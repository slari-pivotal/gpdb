drop database create_objects_db;
drop database create_table_db;
drop database db_tobe_vacuum;
drop database db_tobe_vacuum_analyze;
drop database db_test;
drop database ao_db;
drop database partition_db;
drop database check_oid_relfilenode_db;
drop database vacuum_data_db;
drop database unvacuum_data_db;
drop database "TEST_DB";
drop database test_db;
drop database "TEST_db";
drop database test_db1;
drop database alter_table_db;
drop database cancel_trans;
drop database ao_table_drop_col1;
drop database ao_table_drop_col2;
drop database ao_table_drop_col3;
drop database co_db;
drop database co_table_drop_col3;

drop user "MAIN_USER";
drop user "sub_user" ;
drop user "SUB_user_1";
drop user "user123" ;

drop role  user_1;
drop role "ISO";
drop role "geography" ;
drop role "ISO_ro_1";
drop role "iso123" ;

drop GROUP prachgrp;
create database db_test_bed;
\c db_test_bed
DROP RESOURCE QUEUE db_resque2;
DROP RESOURCE QUEUE DB_RESque3;
DROP RESOURCE QUEUE DB_RESQUE4;

DROP ROLE db_role1;
DROP ROLE db_role2;
DROP ROLE db_role3;
DROP ROLE db_role4;
DROP ROLE db_role5;
DROP ROLE db_role6;
DROP ROLE db_role7;
DROP ROLE new_role8;
DROP ROLE db_role9;
DROP ROLE db_role10;
DROP ROLE db_role11;
DROP ROLE db_role12;
DROP GROUP db_grp1;
DROP SCHEMA db_schema1;

DROP GROUP db_user_grp1;
DROP ROLE db_user1;
DROP ROLE db_user2;
DROP ROLE db_user3;
DROP ROLE db_user4;
DROP ROLE db_user5;
DROP ROLE db_user6;
DROP ROLE db_user7;
DROP ROLE new_user8;
DROP ROLE db_user9;
DROP ROLE db_user10;
DROP ROLE db_user11;
DROP ROLE db_user12;
DROP SCHEMA db_schema2;
DROP RESOURCE QUEUE resqueu3;
DROP RESOURCE QUEUE resqueu4;

DROP DATABASE db_schema_test;
DROP USER db_user13 ;

DROP ROLE db_owner1;
DROP DATABASE db_name1;
DROP ROLE db_owner2;
DROP SCHEMA myschema;

DROP GROUP db_group1; 
DROP GROUP db_grp2;
DROP GROUP db_grp3;
DROP GROUP db_grp4;
DROP GROUP db_grp5;
DROP GROUP db_grp6;
DROP GROUP db_grp7;
DROP GROUP db_grp8;
DROP GROUP db_grp9;
DROP GROUP db_grp10;
DROP GROUP db_grp11;
DROP GROUP db_grp12;
DROP ROLE grp_role1;
DROP ROLE grp_role2;
DROP USER test_user_1;
DROP RESOURCE QUEUE grp_rsq1 ;

DROP RESOURCE QUEUE db_resque1;

DROP TABLE test_tbl;
DROP SEQUENCE  db_seq3;
DROP SEQUENCE  db_seq4;
DROP SEQUENCE  db_seq5;
DROP SEQUENCE  db_seq7;
DROP SCHEMA db_schema9 CASCADE;

DROP TABLE test_emp CASCADE;

DROP LANGUAGE plpgsql CASCADE;

DROP DOMAIN domain_us_zip_code;
DROP DOMAIN domain_1;
DROP DOMAIN domain_2;
DROP SCHEMA domain_schema CASCADE;
DROP ROLE domain_owner;

DROP FUNCTION scube_accum(numeric, numeric)CASCADE;
DROP FUNCTION pre_accum(numeric, numeric)CASCADE;
DROP FUNCTION final_accum(numeric)CASCADE;
DROP ROLE agg_owner;
DROP SCHEMA agg_schema;
DROP FUNCTION add(integer, integer) CASCADE; 
DROP ROLE func_role ;
DROP SCHEMA func_schema; 

DROP VIEW IF EXISTS emp_view CASCADE;
DROP TABLE test_emp_view;

DROP ROLE sally;
DROP ROLE ron;
DROP ROLE ken;
\c db_test_bed 
DROP TABLE if exists sch_tbint CASCADE;
DROP TABLE if exists sch_tchar CASCADE;
DROP TABLE if exists sch_tclob CASCADE;
DROP TABLE if exists sch_tversion CASCADE;
DROP TABLE if exists sch_tjoin2 CASCADE;
DROP TABLE if exists sch_T29 CASCADE;
DROP TABLE if exists sch_T33 CASCADE;
DROP TABLE if exists sch_T43 CASCADE;
DROP view if exists sch_srf_view1;
DROP view if exists sch_fn_view2;
DROP FUNCTION sch_multiply(integer,integer);
\c template1
DROP DATABASE db_test_bed;
DROP ROLE admin ;
\c gptest
drop table region_hybrid_part;
drop table nation_hybrid_part;
drop table part_hybrid_part;
drop table partsupp_hybrid_part;
drop table supplier_hybrid_part;
drop table orders_hybrid_part;
drop table lineitem_hybrid_part;
drop table customer_hybrid_part;
\c template1
drop database heap_table_drop_col3;
