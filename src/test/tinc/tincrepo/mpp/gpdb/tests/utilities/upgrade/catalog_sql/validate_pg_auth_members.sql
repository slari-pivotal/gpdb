--
-- check pg_auth_members
--

\d pg_auth_members

select 
  a.rolname as roleid,
  b.rolname as member,
  c.rolname as grantor,
  u.admin_option
from pg_auth_members u
left join pg_authid a on (a.oid = u.roleid)
left join pg_authid b on (b.oid = u.member)
left join pg_authid c on (c.oid = u.grantor)
order by a.rolname, b.rolname, c.rolname;
