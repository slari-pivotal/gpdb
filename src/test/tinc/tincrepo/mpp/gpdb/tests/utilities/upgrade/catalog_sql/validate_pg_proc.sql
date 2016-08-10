--
-- check pg_proc - stored procedures
--   * ACLs check in checkacl.sql
--

\d pg_proc

--  We assume no function has more than 10 arguments, if not true the test 
--  should be modified
--  Additionally we currently rely on ordering by OID on the parameter types, 
--  we may need to modify this to a more stable ordering.
SELECT max(pronargs) from pg_proc;

-- function basics:
SELECT
  n.nspname,
  p.proname,
  l.lanname,
  p.proisagg,
  p.prosecdef,
  p.proisstrict,
  p.proretset,
  p.provolatile,
  p.pronargs,
  p.prorettype::regtype,
  p.proiswin,
  p.prosrc,
  p.probin
FROM pg_proc p 
left join pg_namespace n on (n.oid = p.pronamespace)
left join pg_user u on (u.usesysid = p.proowner)
left join pg_language l on (l.oid = p.prolang)
order by n.nspname, p.proname, p.pronargs, 
         p.proargtypes[0], p.proargtypes[1], p.proargtypes[2], p.proargtypes[3],
         p.proargtypes[4], p.proargtypes[5], p.proargtypes[6], p.proargtypes[7],
         p.proargtypes[8], p.proargtypes[9]
;

-- function arguments
SELECT
  n.nspname,
  p.proname,
  p.i,
  p.proargtypes[i-1]::regtype
FROM (select *, generate_series(1, pronargs) as i from pg_proc) p
left join pg_namespace n on (n.oid = p.pronamespace)
order by n.nspname, p.proname, p.pronargs, 
         p.proargtypes[0], p.proargtypes[1], p.proargtypes[2], p.proargtypes[3],
         p.proargtypes[4], p.proargtypes[5], p.proargtypes[6], p.proargtypes[7],
         p.proargtypes[8], p.proargtypes[9],
         i;

-- function argument modes
SELECT
  n.nspname,
  p.proname,
  p.i,
  p.proallargtypes[i]::regtype,
  p.proargmodes[i]
FROM (select *, generate_series(1, array_upper(proargmodes, 1)) as i from pg_proc 
      where proargmodes is not null) p
left join pg_namespace n on (n.oid = p.pronamespace)
order by n.nspname, p.proname, p.pronargs, 
         p.proargtypes[0], p.proargtypes[1], p.proargtypes[2], p.proargtypes[3],
         p.proargtypes[4], p.proargtypes[5], p.proargtypes[6], p.proargtypes[7],
         p.proargtypes[8], p.proargtypes[9],
         i;


-- catalog only check
select * 
from pg_proc where oid < 10000
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18;

select * 
from pg_proc where oid < 10000
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18;
