--
-- check pg_aggregate
--

\d pg_aggregate

-- Use the function ordering -- see pg_proc.sql
select 
  n.nspname as namespace,
  p.proname as aggname,
  a.aggtransfn,
  a.agginvtransfn,
  a.aggprelimfn,
  a.agginvprelimfn,
  a.aggfinalfn,
  o.oprname as sortop,
  a.aggtranstype::regtype,
  a.agginitval
from pg_catalog.pg_aggregate a
left outer join pg_proc p on (p.oid = a.aggfnoid)
left outer join pg_namespace n on (n.oid = p.pronamespace)
left outer join pg_operator o on (o.oid = a.aggsortop)
order by n.nspname, p.proname, p.pronargs, 
         p.proargtypes[1], p.proargtypes[2], p.proargtypes[3], p.proargtypes[4],
         p.proargtypes[5], p.proargtypes[6], p.proargtypes[7], p.proargtypes[8],
         p.proargtypes[9], p.proargtypes[10]
;


select
  n.nspname as namespace,
  p.proname as aggname,
  a.aggtransfn,
  a.agginvtransfn,
  a.aggprelimfn,
  a.agginvprelimfn,
  a.aggfinalfn,
  o.oprname as sortop,
  a.aggtranstype::regtype,
  a.agginitval
from pg_aggregate a
left outer join pg_proc p on (p.oid = a.aggfnoid)
left outer join pg_namespace n on (n.oid = p.pronamespace)
left outer join pg_operator o on (o.oid = a.aggsortop)
order by 1,2,3,4,5,6,7,8,9,10
;
