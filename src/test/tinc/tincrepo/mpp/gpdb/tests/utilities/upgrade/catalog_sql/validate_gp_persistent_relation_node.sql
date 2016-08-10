--
-- gp_persistent_relation_node
--
-- This is a shared table that contains information for all databases in the cluster
-- since we will be checking each database in turn and we can't really investigate contents
-- of other databases from an active connection we restrict to the current database.

SELECT
  d.datname                             as "database",
  t.spcname                             as "tablespace",
  n.nspname                             as "schema",
  c.relname                             as "relname",
  p.segment_file_num                    as "segnum",
  p.relation_storage_manager            as "stormgr",
  case when p.persistent_state = 0 then 'free'
       when p.persistent_state = 1 then 'create pending'
	   when p.persistent_state = 2 then 'created'
       when p.persistent_state = 3 then 'drop pending'
	   when p.persistent_state = 4 then 'abort create'
	   when p.persistent_state = 5 then 'JIT create pending'
	   else 'unknown state: ' || p.persistent_state
  end  as "state",
  case when p.mirror_existence_state = 0 then 'none'
       when p.mirror_existence_state = 1 then 'not mirrored'
	   when p.mirror_existence_state = 2 then 'create pending'
	   when p.mirror_existence_state = 3 then 'created'
	   when p.mirror_existence_state = 4 then 'recreate needed'
	   when p.mirror_existence_state = 5 then 'redrop needed'
	   when p.mirror_existence_state = 6 then 'dropped'
	   else 'unknown state: ' || p.mirror_existence_state
  end  as "mirror state",
  case when p.mirror_data_synchronization_state = 0 then 'none'
       when p.mirror_data_synchronization_state = 1 then 'synchronized'
       when p.mirror_data_synchronization_state = 2 then 'full copy'
       when p.mirror_data_synchronization_state = 3 then 'bufpool page'
       when p.mirror_data_synchronization_state = 4 then 'bufpool scan'
       when p.mirror_data_synchronization_state = 5 then 'ao catchup'
       else 'unkown state: ' || p.mirror_data_synchronization_state
  end  as "mirror sync",
--  p.mirror_bufpool_physically_truncated as "mirtrunc",
--  p.mirror_bufpool_resync_ckpt_loc      as "mirckloc",
--  p.mirror_bufpool_resync_ckpt_block_num as "mirckblk",
--  p.mirror_append_only_loss_eof         as "miraoloss",
--  p.mirror_append_only_new_eof          as "miraonew",
  p.parent_xid                          as "parxid"
--  ,p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  pg_catalog.gp_persistent_relation_node p
  join pg_catalog.pg_database d on (p.database_oid = d.oid)
  join pg_catalog.pg_tablespace t on (p.tablespace_oid = t.oid)
  join validator.pg_class_view c on (p.relfilenode_oid = c.relfilenode)
  join pg_catalog.pg_namespace n on (c.relnamespace = n.oid)
WHERE
  d.datname = current_database()
ORDER BY 1, 2, 3, 4, 5;


--
-- Also need to check the results of the persistent tables on the segments
-- since that is where the real mirroring occurs.
--
SELECT
  d.datname                             as "database",
  t.spcname                             as "tablespace",
  n.nspname                             as "schema",
  c.relname                             as "relname",
  p.segment_file_num                    as "segnum",
  p.relation_storage_manager            as "stormgr",
  case when p.persistent_state = 0 then 'free'
       when p.persistent_state = 1 then 'create pending'
	   when p.persistent_state = 2 then 'created'
       when p.persistent_state = 3 then 'drop pending'
	   when p.persistent_state = 4 then 'abort create'
	   when p.persistent_state = 5 then 'JIT create pending'
	   else 'unknown state: ' || p.persistent_state
  end  as "state",
  case when p.mirror_existence_state = 0 then 'none'
       when p.mirror_existence_state = 1 then 'not mirrored'
	   when p.mirror_existence_state = 2 then 'create pending'
	   when p.mirror_existence_state = 3 then 'created'
	   when p.mirror_existence_state = 4 then 'recreate needed'
	   when p.mirror_existence_state = 5 then 'redrop needed'
	   when p.mirror_existence_state = 6 then 'dropped'
	   else 'unknown state: ' || p.mirror_existence_state
  end  as "mirror state",
-- Suchitra: Commenting out mirror sync from query 
-- Per Alan: Can be ignored since 1. Validator should work for with and without mirror 2. Chance that mirror is still in re-sync mode when validator is run
--  case when p.mirror_data_synchronization_state = 0 then 'none'
--       when p.mirror_data_synchronization_state = 1 then 'synchronized'
--       when p.mirror_data_synchronization_state = 2 then 'full copy'
--       when p.mirror_data_synchronization_state = 3 then 'bufpool page'
--       when p.mirror_data_synchronization_state = 4 then 'bufpool scan'
--       when p.mirror_data_synchronization_state = 5 then 'ao catchup'
--       else 'unkown state: ' || p.mirror_data_synchronization_state
--  end  as "mirror sync",

--  p.mirror_bufpool_physically_truncated as "mirtrunc",
--  p.mirror_bufpool_resync_ckpt_loc      as "mirckloc",
--  p.mirror_bufpool_resync_ckpt_block_num as "mirckblk",
--  p.mirror_append_only_loss_eof         as "miraoloss",
--  p.mirror_append_only_new_eof          as "miraonew",
  p.parent_xid                          as "parxid"
--  ,p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  (select *, gp_execution_segment() as segment
   from pg_catalog.gp_persistent_relation_node) p
  join pg_catalog.pg_database d on (p.database_oid = d.oid)
  join pg_catalog.pg_tablespace t on (p.tablespace_oid = t.oid)
  join validator.pg_class_view c on (p.relfilenode_oid = c.relfilenode)
  join pg_catalog.pg_namespace n on (c.relnamespace = n.oid)
WHERE
  d.datname = current_database()
ORDER BY 1, 2, 3, 4, 5, 6;
