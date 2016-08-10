--
-- pg_appendonly_alter_column
--

\d pg_appendonly_alter_column

select
  nspname, relname, changenum, segfilenums
from pg_appendonly_alter_column a
left join pg_class r on (a.relid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname;