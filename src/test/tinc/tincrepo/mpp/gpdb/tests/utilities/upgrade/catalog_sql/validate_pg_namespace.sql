--
-- pg_namespace
--   ACLs check in aclcheck.sql
--

\d pg_namespace

select
  n.nspname
from
  pg_namespace n
  left join pg_authid o on (n.nspowner = o.oid)
order by n.nspname;
