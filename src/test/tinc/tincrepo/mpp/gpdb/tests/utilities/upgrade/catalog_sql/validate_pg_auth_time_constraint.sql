--
-- pg_auth_time_constraint (Added in Rio)
--
--"QA-1988: omit authid because generated OIDs differ between UPGRADED and FRESH server"

\d pg_auth_time_constraint

select
  i.rolname as rolname,
  a.start_day,
  a.start_time,
  a.end_day,
  a.end_time
from pg_auth_time_constraint a
left join pg_authid i on (a.authid = i.oid)
order by i.rolname, a.authid;

select
  i.rolname as rolname,
  start_day,
  start_time,
  end_day,
  end_time
from pg_auth_time_constraint a
left join pg_authid i on (a.authid = i.oid)
order by rolname, authid;
