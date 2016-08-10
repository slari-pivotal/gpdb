--
--  pg_description - object descriptions
--

\d pg_shdescription

SELECT 
  u.catname, 
  n.nspname,
  u.objname,
  d.description
FROM
  pg_shdescription d 
  left outer join validator.pg_oid_tables u on (d.objoid = u.oid and d.classoid = u.catname::regclass)
  left outer join pg_namespace n on (u.nspoid = n.oid)
order by u.catname, n.nspname, u.objname, d.description;
