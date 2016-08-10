--
-- check pg_attribute
--

\d pg_attribute

SELECT count(*) from pg_attribute;

SELECT
  n.nspname,
  r.relname,
  a.attname,
  a.atttypid::regtype,
  a.attstattarget,
  a.attlen,
  a.attnum,
  a.attndims,
  a.attcacheoff,
  a.atttypmod,
  a.attbyval,
  a.attstorage,
  a.attalign,
  a.attnotnull,
  a.atthasdef,
  a.attisdropped,
  a.attislocal,
  a.attinhcount
FROM pg_attribute a
left join validator.pg_class_view r on (r.oid = a.attrelid)
left join pg_namespace n on (n.oid = r.relnamespace)
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18;

SELECT
  n.nspname,
  r.relname,
  a.attname,
  a.atttypid::regtype,
  a.attstattarget,
  a.attlen,
  a.attnum,
  a.attndims,
  a.attcacheoff,
  a.atttypmod,
  a.attbyval,
  a.attstorage,
  a.attalign,
  a.attnotnull,
  a.atthasdef,
  a.attisdropped,
  a.attislocal,
  a.attinhcount
FROM pg_attribute a
left join validator.pg_class_view r on (r.oid = a.attrelid)
left join pg_namespace n on (n.oid = r.relnamespace)
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18;
