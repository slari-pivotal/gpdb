--
-- check pg_class - relation like things
--   * ACLs check in checkacl.sql
--

\d pg_class

--
-- the "statistics" columns relpages, reltuples are queried in pg_statistics 
-- intsead of here.
--
SELECT
  n.nspname,
  r.relname,
  t.typname,
  a.amname,
  -- r.relfilenode,
  ts.spcname,
  -- r.relpages,
  -- r.reltuples,
  -- r.reltoastrelid
  -- r.reltoastidxid
  -- r.relaosegrelid
  -- r.relaosegidxid
  r.relhasindex,
  r.relisshared,
  r.relkind,
  r.relstorage,
  r.relnatts,
  -- r.relchecks, DO NOT check relchecks for 4.2 upgrade due to partition behavior change; it's check by pg_constrain.sql anyway.
  r.reltriggers,
  r.relukeys,
  r.relfkeys,
  r.relrefs,
  r.relhasoids,
  case when (n.nspname ~ 'pg_toast') then false else r.relhaspkey end,
  r.relhasrules,
  r.relhassubclass,
  -- r.relfrozenxid
  r.reloptions
FROM validator.pg_class_view r
left join validator.pg_type_view t on (r.reltype = t.oid)
left join pg_namespace n on (n.oid = r.relnamespace)
left join pg_user u on (u.usesysid = r.relowner)
left join pg_am a on (a.oid = r.relam)
left join pg_tablespace ts on (ts.oid = r.reltablespace)
order by n.nspname, r.relname
;
