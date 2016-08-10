--
-- pg_inherits
--

\d pg_inherits

select 
  n1.nspname as rel_namespace,
  r1.relname as rel_name,
  n2.nspname as parent_namespace,
  r2.relname as parent_name,
  i.inhseqno
from pg_catalog.pg_inherits i
left join pg_class r1 on (i.inhrelid = r1.oid)
left join pg_class r2 on (i.inhparent = r2.oid)
left join pg_namespace n1 on (r1.relnamespace = n1.oid)
left join pg_namespace n2 on (r2.relnamespace = n2.oid)
order by n1.nspname, r1.relname, n2.nspname, r2.relname, i.inhseqno;