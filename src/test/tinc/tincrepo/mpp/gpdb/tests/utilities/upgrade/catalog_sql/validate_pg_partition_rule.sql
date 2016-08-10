--
-- pg_partition_rule
--

\d pg_partition_rule

-- The best query for partition_rule is to use the built in view "pg_partitions"
\d pg_partitions

select * from pg_partitions
order by schemaname, tablename, partitionschemaname, partitiontablename;

