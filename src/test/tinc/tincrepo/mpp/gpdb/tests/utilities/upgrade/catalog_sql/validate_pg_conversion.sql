--
-- pg_conversion
--

\d pg_conversion

select
  n.nspname as namespace,
  c.conname,
  c.conforencoding,
  c.contoencoding,
  c.conproc,
  c.condefault
from pg_conversion c
join pg_namespace n on (c.connamespace = n.oid)
join pg_authid u on (c.conowner = u.oid)
order by n.nspname, c.conname;
