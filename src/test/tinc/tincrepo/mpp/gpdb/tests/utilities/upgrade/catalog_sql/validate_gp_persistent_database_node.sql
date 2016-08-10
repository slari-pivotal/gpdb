--
-- gp_persistent_database_node
--
-- a shared table by database, get the relevant information for this database.

-- Should have exactly one row per database
SELECT
  d.datname                             as "database",
  t.spcname                             as "tablespace",
  case when p.persistent_state = 0 then 'free'
       when p.persistent_state = 1 then 'create pending'
	   when p.persistent_state = 2 then 'created'
       when p.persistent_state = 3 then 'drop pending'
	   when p.persistent_state = 4 then 'abort create'
	   when p.persistent_state = 5 then 'JIT create pending'
	   else 'unknown mode: ' || p.persistent_state
  end  as "state",
  case when p.mirror_existence_state = 0 then 'none'
       when p.mirror_existence_state = 1 then 'not mirrored'
	   when p.mirror_existence_state = 2 then 'create pending'
	   when p.mirror_existence_state = 3 then 'created'
	   when p.mirror_existence_state = 4 then 'recreate needed'
	   when p.mirror_existence_state = 5 then 'redrop needed'
	   when p.mirror_existence_state = 6 then 'dropped'
	   else 'unknown mode: ' || p.mirror_existence_state
  end  as "mirror state",
  p.parent_xid                          as "parxid"
--  p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  pg_catalog.gp_persistent_database_node p
  join pg_catalog.pg_database d on (p.database_oid = d.oid)
  join pg_catalog.pg_tablespace t on (p.tablespace_oid = t.oid)
WHERE
  d.datname = current_database()
ORDER BY 1,2;

--
-- Also need to check on the segments
--
SELECT
  p.segment,
  d.datname                             as "database",
  t.spcname                             as "tablespace",
  case when p.persistent_state = 0 then 'free'
       when p.persistent_state = 1 then 'create pending'
	   when p.persistent_state = 2 then 'created'
       when p.persistent_state = 3 then 'drop pending'
	   when p.persistent_state = 4 then 'abort create'
	   when p.persistent_state = 5 then 'JIT create pending'
	   else 'unknown mode: ' || p.persistent_state
  end  as "state",
  case when p.mirror_existence_state = 0 then 'none'
       when p.mirror_existence_state = 1 then 'not mirrored'
	   when p.mirror_existence_state = 2 then 'create pending'
	   when p.mirror_existence_state = 3 then 'created'
	   when p.mirror_existence_state = 4 then 'recreate needed'
	   when p.mirror_existence_state = 5 then 'redrop needed'
	   when p.mirror_existence_state = 6 then 'dropped'
	   else 'unknown mode: ' || p.mirror_existence_state
  end  as "mirror state",
  p.parent_xid                          as "parxid"
--  p.persistent_serial_num               as "serialnum",
--  p.previous_free_tid                   as "freetid"
FROM
  (select *, gp_execution_segment() as segment
   from pg_catalog.gp_persistent_database_node) p
  join pg_catalog.pg_database d on (p.database_oid = d.oid)
  join pg_catalog.pg_tablespace t on (p.tablespace_oid = t.oid)
WHERE
  d.datname = current_database()
ORDER BY 1,2,3;
