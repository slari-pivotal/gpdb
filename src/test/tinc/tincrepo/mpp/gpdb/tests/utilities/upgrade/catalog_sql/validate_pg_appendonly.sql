--
-- pg_appendonly
--

\d pg_appendonly

select
  n.nspname,
  r.relname,
  a.blocksize,
  a.safefswritesize,
  a.compresslevel,
  a.majorversion,
  a.minorversion,
  a.checksum,
  a.compresstype,
  a.columnstore
from pg_appendonly a
left join pg_class r on (a.relid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname;