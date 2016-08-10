--
-- pg_exttable
--

\d pg_exttable

select
  n.nspname,
  r.relname,
  e.location,
  e.fmttype,
  e.fmtopts,
  e.command,
  e.rejectlimit,
  e.rejectlimittype,
  e.fmterrtbl::regclass,
  e.encoding
from pg_exttable e
left join pg_class r on (e.reloid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname;