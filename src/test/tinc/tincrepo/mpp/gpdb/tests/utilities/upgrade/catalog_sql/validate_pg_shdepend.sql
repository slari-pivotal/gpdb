--
--  Check pg_shdepend
--

\d pg_shdepend

-- Quick summary
SELECT classid::regclass, count(*) from pg_shdepend group by classid;

-- Messy details
SELECT
  d.deptype,
  db.datname,
  l.catname, 
  coalesce(n1.nspname || '.', '') || l.objname as obj
FROM pg_shdepend d
left outer join pg_database db on (d.dbid = db.oid)
left outer join validator.pg_oid_tables l on (d.classid = l.catname::regclass and d.objid = l.oid)
left outer join validator.pg_oid_tables r on (d.refclassid = r.catname::regclass and d.refobjid = r.oid)
left outer join pg_namespace n1 on (l.nspoid = n1.oid)
left outer join pg_namespace n2 on (r.nspoid = n2.oid)
where (db.datname is null or db.datname = current_database())
order by d.deptype, l.catname, n1.nspname, l.objname, 
                    r.catname, n2.nspname, r.objname;
