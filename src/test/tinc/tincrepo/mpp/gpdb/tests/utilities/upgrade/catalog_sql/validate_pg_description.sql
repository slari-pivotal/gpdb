--
--  pg_description - object descriptions
--

\d pg_description

SELECT 
  u.catname, 
  n.nspname,
  u.objname,
  d.objsubid,
  d.description
FROM
  pg_description d 
  left outer join validator.pg_oid_tables u on (d.objoid = u.oid and d.classoid = u.catname::regclass)
  left outer join pg_namespace n on (u.nspoid = n.oid)
order by u.catname, n.nspname, u.objname, d.objsubid, d.description;


---
--- disable segment check because comments are not dispatched
---
---SELECT 
---  u.catname, 
---  n.nspname,
---  u.objname,
---  d.objsubid,
---  d.description
---FROM
---  gp_dist_random('pg_description') d 
---  left outer join validator.pg_oid_tables u on (d.objoid = u.oid and d.classoid = u.catname::regclass)
---  left outer join pg_namespace n on (u.nspoid = n.oid)
---order by u.catname, n.nspname, u.objname, d.objsubid, d.description;
