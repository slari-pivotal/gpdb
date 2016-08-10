--
-- pg_index
--
-- @product_version gpdb: 4.3.4.1AS

\d pg_index

-- This query unnests the indclass vector (with ordinality)
select
  n1.nspname as indexnamespace,
  r1.relname as indexname,
  n2.nspname as indnamespace,
  r2.relname as indname,
  i.indnatts,
  i.indisunique,
  i.indisprimary,
  i.indisclustered,
  i.indisvalid,
  i.indkey,
  i.indexprs,
  i.indpred,
  i.i,
  o.opcname as indclass_i
from (select *, generate_series(0, array_upper(indclass,1)) as i from pg_index) i
left join pg_opclass o on (o.oid = i.indclass[i.i])
left join validator.pg_class_view r1 on (i.indexrelid = r1.oid)
left join validator.pg_class_view r2 on (i.indrelid = r2.oid)
left join pg_namespace n1 on (r1.relnamespace = n1.oid)
left join pg_namespace n2 on (r2.relnamespace = n2.oid)
order by n1.nspname, r1.relname, n2.nspname, r2.relname, i;

select
  n1.nspname as indexnamespace,
  r1.relname as indexname,
  n2.nspname as indnamespace,
  r2.relname as indname,
  i.indnatts,
  i.indisunique,
  i.indisprimary,
  i.indisclustered,
  i.indisvalid,
  i.indkey,
  i.indexprs,
  i.indpred,
  i.i,
  o.opcname as indclass_i
from (select *, generate_series(0, array_upper(indclass,1)) as i from pg_index) i
left join pg_opclass o on (o.oid = i.indclass[i.i])
left join validator.pg_class_view r1 on (i.indexrelid = r1.oid)
left join validator.pg_class_view r2 on (i.indrelid = r2.oid)
left join pg_namespace n1 on (r1.relnamespace = n1.oid)
left join pg_namespace n2 on (r2.relnamespace = n2.oid)
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14;
