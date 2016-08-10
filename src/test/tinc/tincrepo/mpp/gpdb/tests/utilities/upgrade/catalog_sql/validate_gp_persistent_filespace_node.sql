--
-- gp_persistent_filespace_node
--
-- a shared table, but not by database, so every database will check the full thing.
--

-- Only contains values for non-default filespaces, should be empty.
SELECT
  f.fsname                              as "filespace",
  p.db_id_1                             as "dbid_1",
  p.db_id_2                             as "dbid_2",
  p.location_1::text                    as "location_1",
  p.location_2::text                    as "location_2",
  case when p.persistent_state = 0 then 'free'
       when p.persistent_state = 1 then 'create pending'
	   when p.persistent_state = 2 then 'created'
       when p.persistent_state = 3 then 'drop pending'
	   when p.persistent_state = 4 then 'abort create'
	   when p.persistent_state = 5 then 'JIT create pending'
	   else 'unknown mode: ' || p.persistent_state
  end  as "perstate",
  case when p.mirror_existence_state = 0 then 'none'
       when p.mirror_existence_state = 1 then 'not mirrored'
	   when p.mirror_existence_state = 2 then 'create pending'
	   when p.mirror_existence_state = 3 then 'created'
	   when p.mirror_existence_state = 4 then 'recreate needed'
	   when p.mirror_existence_state = 5 then 'redrop needed'
	   when p.mirror_existence_state = 6 then 'dropped'
	   else 'unknown mode: ' || p.mirror_existence_state
  end  as "mirstate",
  p.parent_xid                          as "parxid"
--  p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  pg_catalog.gp_persistent_filespace_node p
  join pg_catalog.pg_filespace f on (p.filespace_oid = f.oid)
ORDER BY 1;