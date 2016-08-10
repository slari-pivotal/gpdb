--
-- gp_relation_node
--
-- This is similar to gp_persistent_relation_node, but is local to this
-- database and does not contain mirroring information.

SELECT
  n.nspname                             as "schema",
  c.relname                             as "relname",
  p.segment_file_num                    as "segnum"
--  ,p.persistent_tid                      as "pertid",
--  p.persistent_serial_num               as "serialnum"
FROM
  pg_catalog.gp_relation_node p
  join validator.pg_class_view c on (p.relfilenode_oid = c.relfilenode)
  join pg_catalog.pg_namespace n on (c.relnamespace = n.oid)
ORDER BY 1, 2, 3;
