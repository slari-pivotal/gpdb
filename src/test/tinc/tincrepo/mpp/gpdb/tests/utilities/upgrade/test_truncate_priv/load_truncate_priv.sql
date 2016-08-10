create role truncate_priv;
set role truncate_priv;

create table truncate_priv_test(a int, b int);
grant all on truncate_priv_test to truncate_priv;
truncate truncate_priv_test;
