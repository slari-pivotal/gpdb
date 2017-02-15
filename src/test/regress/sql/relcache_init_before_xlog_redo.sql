-- Purpose of test is to catch relcache initialization before xlog replay.
-- We have to use template1 because this database is used during recovery.
--
\c template1
-- create a record in pg_class
create table table_to_be_dropped (c int) distributed by (c);
-- make sure the pg_type_oid_index moved to the end of pg_class
reindex index pg_type_oid_index;
-- leave an empty place in middle for next create table, so that,
-- we can create new table record before system index.
-- If relcache is initialized before xlog replay, this record will be
-- populate with a wrong hint bit (i.e. XMIN_INVALID)
drop table table_to_be_dropped;
-- make the space
vacuum pg_class;
begin;
-- this will reuse the empty place left before
create table table_to_be_committed (c int) distributed by (c);
-- start_ignore
select ctid, xmin, xmax
from gp_dist_random('pg_class')
where gp_segment_id = 0
and relname = 'table_to_be_committed';

select ctid, xmin, xmax
from gp_dist_random('pg_class')
where gp_segment_id = 0
and relname = 'pg_type_oid_index';
-- end_ignore
select case when (select ctid from pg_class where relname = 'table_to_be_committed') < (select ctid
from pg_class where relname = 'pg_type_oid_index') then 'true' else 'false' end;
-- We have to start a new session to do the checkpoint, since checkpoint cannot be
-- executed inside a transaction. We want to make sure the entries of table_to_be_committed
-- is before pg_type_oid_index in pg_class.
\! psql template1 -c 'checkpoint'
-- caused PANIC (cause restart) on seg0
\! gpfaultinjector -f before_transaction_id_commit -y panic --seg_dbid 2
commit;
-- reset the fault injector
\! gpfaultinjector -f all -y reset -H all -r primary

-- verify the table_to_be_committed is visible on seg0
select relname, gp_segment_id
from gp_dist_random('pg_class')
where relname = 'table_to_be_committed'
and gp_segment_id = 0;

-- cleanup
drop table table_to_be_committed;
