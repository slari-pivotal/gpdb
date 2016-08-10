--
-- All catalogs with oids
--
select oid, relname 
from   validator.pg_class_view
where  relnamespace=11 and relkind='r' and relhasoids
order by oid;

--
-- There should be no duplicate oids
--
select oid from validator.pg_oid_tables group by oid having count(*) > 1;

--
-- Union all catalogs with oids
--  * All OIDS < 1000 must be constant
--
SELECT oid, catname, nspname
FROM validator.pg_oid_tables u
left outer join pg_namespace n on (u.nspoid = n.oid)
where oid < 10000
order by oid;

SELECT oid, catname, nspname
FROM validator.pg_oid_tables_seg u
left outer join pg_namespace n on (u.nspoid = n.oid)
where oid < 10000
order by oid;

--
-- Union all catalogs with oids
--   - Catalog objects over oid 10000 should all match, but the oids
--     are allowed to shift during upgrade.
--   - This misses the toast tables because they are in the pg_toast
--     schema.  It is difficult to differentiate these from user toast
--     tables
--
SELECT u.catname, nspname, objname
FROM validator.pg_oid_tables u
left outer join pg_namespace n on (u.nspoid = n.oid)
where oid >= 10000 and nspname in ('pg_catalog', 'information_schema')
order by u.catname, nspname, objname;

SELECT u.catname, nspname, objname
FROM validator.pg_oid_tables_seg u
left outer join pg_namespace n on (u.nspoid = n.oid)
where oid >= 10000 and nspname in ('pg_catalog', 'information_schema')
order by u.catname, nspname, objname;
