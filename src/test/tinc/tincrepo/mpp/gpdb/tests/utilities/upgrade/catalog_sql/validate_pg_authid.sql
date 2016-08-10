--
-- check pg_authid, pg_auth_members
--

\d pg_authid

select 
  rolinherit,
  rolcreaterole,
  rolcreatedb,
  rolcatupdate,
  rolcanlogin,
  rolconnlimit,
  rolvaliduntil,
  rolconfig,
  rsqname as rolresqueue
from pg_authid a
left join pg_resqueue q on (a.rolresqueue = q.oid)
order by rolname;

