--
-- pg_window
--

\d pg_window


--  see pg_proc.sql
--  this uses function arguments to disambiguate in the ordering,
--  if we have window functions with > 10 arguments this needs to be adjusted
--  Additionally we currently rely on ordering by OID on the parameter types, 
--  we may need to modify this to a more stable ordering.
select
  n.nspname as namespace,
  p.proname as windowname,
  w.winrequireorder,
  w.winallowframe,
  w.winpeercount,
  w.wincount,
  w.winfunc,
  w.winprefunc,
  w.winpretype::regtype,
  w.winfinfunc,
  w.winkind
from pg_window w
left join pg_proc p on (w.winfnoid = p.oid)
left join pg_namespace n on (p.pronamespace = n.oid)
order by n.nspname, p.proname, p.pronargs, 
         p.proargtypes[0], p.proargtypes[1], p.proargtypes[2], p.proargtypes[3],
         p.proargtypes[4], p.proargtypes[5], p.proargtypes[6], p.proargtypes[7],
         p.proargtypes[8], p.proargtypes[9];