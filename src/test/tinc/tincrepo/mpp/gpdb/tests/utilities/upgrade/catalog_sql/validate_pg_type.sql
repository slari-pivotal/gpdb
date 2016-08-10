-- 
-- Check the TYPE table
--
\d pg_catalog.pg_type

select 
  n.nspname,
  t.typname,
  t.typlen,
  t.typbyval,
  t.typtype,
  t.typisdefined,
  t.typdelim,
  r.relname as typrelid,
  t.typelem::regtype,
  t.typinput,
  t.typoutput,
  t.typreceive,
  t.typsend,
  t.typanalyze,
  t.typalign,
  t.typstorage,
  t.typnotnull,
  t.typbasetype::regtype,
  t.typtypmod,
  t.typndims,
  t.typdefaultbin,
  t.typdefault
from validator.pg_type_view t
left join validator.pg_class_view r on (t.typrelid = r.oid)
left join pg_namespace n on (t.typnamespace = n.oid)
left join pg_user u on (t.typowner = u.usesysid)
ORDER by n.nspname, t.typname
;
