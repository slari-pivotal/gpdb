-- 
-- pg_type_encoding (Added in Rio)
--
\d pg_type_encoding

select 
  n.nspname,
  u.usename as owner,
  a.typid::regtype,
  a.typoptions,
  t.typname,
  t.typtype,
  t.typstorage
from pg_type_encoding a
left join pg_type t on (a.typid = t.oid)
left join validator.pg_class_view r on (t.typrelid = r.oid)
left join pg_namespace n on (t.typnamespace = n.oid)
left join pg_user u on (t.typowner = u.usesysid)
order by n.nspname, a.typid;


select
  n.nspname,
  u.usename as owner,
  a.typid::regtype,
  a.typoptions,
  t.typname,
  t.typtype,
  t.typstorage
from pg_type_encoding a
left join pg_type t on (a.typid = t.oid)
left join validator.pg_class_view r on (t.typrelid = r.oid)
left join pg_namespace n on (t.typnamespace = n.oid)
left join pg_user u on (t.typowner = u.usesysid)
order by n.nspname, a.typid;

