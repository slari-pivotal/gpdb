--
-- gp_persistent_tablespace_node
--
-- a shared table, but not by database, so every database will check the full thing.
--


-- Only contains values for non-default tablespaces, should be empty.
SELECT
  f.fsname                              as "filespace",
  t.spcname                             as "tablespace",
  p.persistent_state                    as "perstate",
  p.mirror_existence_state              as "mirstate",
  p.parent_xid                          as "parxid"
--  p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  pg_catalog.gp_persistent_tablespace_node p
  join pg_catalog.pg_filespace f on (p.filespace_oid = f.oid)
  join pg_catalog.pg_tablespace t on (p.tablespace_oid = t.oid)
ORDER BY 1, 2;
