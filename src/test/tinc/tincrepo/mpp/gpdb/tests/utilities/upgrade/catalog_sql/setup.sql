\set ON_ERROR_STOP ON

drop schema if exists validator cascade;
CREATE SCHEMA validator;

-- MD5 checksum for user tables:
--       select md5xor(t) from <TABLE OR VIEW> t;
--

--   Should be "record" not "anyelement", but SQL language functions don't support "record"
create function validator.md5xor_accum(bit, anyelement) returns bit as $$
  SELECT $1 # bit_in(textout('x' || md5(textin(record_out($2)))), 0, 128) 
$$ language sql strict immutable;

create function validator.md5xor_combine(bit, bit) returns bit as $$ 
  SELECT $1 # $2 
$$ language sql strict immutable;

create aggregate validator.md5xor(record) (
  INITCOND = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  STYPE = bit,
  SFUNC = validator.md5xor_accum,
  prefunc = validator.md5xor_combine
);

--
-- We have to create all the validator tables before we populate them so that they can
-- contain the entries that refer to themselves.
--

--
-- DEPRECATED: AK: I'm deprecating these for reasons given below. This design decision
-- arises from QA-1933 and other revelations around the complexity of validator SQL.
--
CREATE TABLE validator.pg_class_view(oid regclass, like pg_class) DISTRIBUTED BY (oid);
CREATE TABLE validator.pg_type_view(oid regtype, like pg_type) DISTRIBUTED BY (oid);
CREATE TABLE validator.pg_oid_tables(catname text, nspoid oid, objname name, oid oid) DISTRIBUTED BY (oid);
CREATE TABLE validator.pg_class_seg_view(like validator.pg_class_view) DISTRIBUTED BY (oid);
CREATE TABLE validator.pg_type_seg_view(like validator.pg_type_view) DISTRIBUTED BY (oid);
CREATE TABLE validator.pg_oid_tables_seg(catname text, nspoid oid, objname name, oid oid) DISTRIBUTED BY (oid);

--------
-- Intro
--------

-- This content forms the core of our validator mechanisms. It directly supports many of the queries
-- found elsewhere in this directory. But more importantly, it will serve as a model for how such
-- queries should be written to encourage performance, maintainability, and above all, correctness. As
-- such, here are a couple of guiding themes:
--
-- 1. Eliminate SQL redundancy - we occassionally have the need to validate segment data. In such instances,
-- it does not make sense to have a master version and a segment local version of the same query. Rather,
-- create one relation/view that captures this information across all gp_segment_ids and create a view
-- on top of this for investigating just the master.
--
-- 2. Ensure correctness - earlier forms of these queries often performed joins of gp_dist_random('pg_something')
-- against gp_dist_random('pg_something_else') with no join criteria on gp_segment_id. This emits tuples in which 
-- a tuple from pg_something on segment 1 is joined against pg_something_else on segment 2, yet such tuples are of no
-- interest to us. (In QA-1933, for example, we had to disable pg_depend.sql because its excessive output was causing
-- the use of gpdiff.pl during post-processing to crash and core dump. I later determined that we had been dumping each
-- unique row N^3 times, where N is the number of segments, and the intent was to dump each unique row N times, once for 
-- each segment.
--
-- 3. Encourage modularity - A monolithic query is not maintainable. 

----------------------------
-- Distributed Lookup Tables
----------------------------

-- These are frequently accessed relations throughout the validator sql. The intent is to materialize and distribute its content.
-- Assumptions:
--    * Note the use of regclass and regtype. Using this mechanism for a distributed query of catalog information, there must
--      be no oid inconsistencies on pg_class and pg_type.
--    * Oids under 10000 must be synchronized. We rely on this for namespace inclusion/exclusion, for example. This is not a large concern,
--      just worth stating. (If such oids are not synchronized, something has gone horribly wrong during initialization/bootstrap.)
-- Suggestions:
--    * Keep an eye on gp_segment_id vs. orig_gp_segment_id. Once we materialize pg_class and pg_type, gp_segment_id != orig_gp_segment_id.
--      As a rule of thumb, use gp_segment_id for views and use orig_gp_segment_id for content we've already materialized.
--          * TODO: Would it just be cleaner to make everything orig_gp_segment_id?
CREATE TABLE validator.pg_class_lookup(orig_gp_segment_id smallint, oid regclass, like pg_class) DISTRIBUTED BY (orig_gp_segment_id, oid);
CREATE TABLE validator.pg_type_lookup(orig_gp_segment_id smallint, oid regtype, like pg_type) DISTRIBUTED BY (orig_gp_segment_id, oid);
CREATE TABLE validator.pg_oid_lookup(orig_gp_segment_id smallint, oid oid, catname text, nspoid oid, objname name) DISTRIBUTED BY (orig_gp_segment_id, oid);

-- Master-only Views
CREATE VIEW validator.pg_class_lookup_master AS SELECT * FROM validator.pg_class_lookup WHERE orig_gp_segment_id = -1;
CREATE VIEW validator.pg_type_lookup_master AS SELECT * FROM validator.pg_type_lookup WHERE orig_gp_segment_id = -1;
CREATE VIEW validator.pg_oid_lookup_master AS SELECT * FROM validator.pg_oid_lookup WHERE orig_gp_segment_id = -1;

-- Temporary/helper views - These are used for formulating the validator.*_lookup tables. If these view
-- themselves are used frequently, we should consider materializing them as well.
-- TODO: Is there a less repetitive, but still clear, way to articulate this? (Note that some relations will lack OIDs.)
CREATE VIEW validator.pg_class_all AS SELECT gp_segment_id, oid, * FROM pg_class UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_class');
CREATE VIEW validator.pg_type_all AS SELECT gp_segment_id, oid, * FROM pg_type UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_type');
CREATE VIEW validator.pg_depend_all AS SELECT gp_segment_id, * FROM pg_depend UNION ALL SELECT gp_segment_id, * FROM gp_dist_random('pg_depend');
CREATE VIEW validator.pg_authid_all AS SELECT gp_segment_id, oid, * FROM pg_authid UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_authid');
CREATE VIEW validator.pg_proc_all AS SELECT gp_segment_id, oid, * FROM pg_proc UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_proc');
CREATE VIEW validator.pg_attrdef_all AS SELECT gp_segment_id, oid, * FROM pg_attrdef UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_attrdef');
CREATE VIEW validator.pg_attribute_all AS SELECT gp_segment_id, * FROM pg_attribute UNION ALL SELECT gp_segment_id, * FROM gp_dist_random('pg_attribute');
CREATE VIEW validator.pg_constraint_all AS SELECT gp_segment_id, oid, * FROM pg_constraint UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_constraint');
CREATE VIEW validator.pg_operator_all AS SELECT gp_segment_id, oid, * FROM pg_operator UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_operator');
CREATE VIEW validator.pg_opclass_all AS SELECT gp_segment_id, oid, * FROM pg_opclass UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_opclass');
CREATE VIEW validator.pg_am_all AS SELECT gp_segment_id, oid, * FROM pg_am UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_am');
CREATE VIEW validator.pg_language_all AS SELECT gp_segment_id, oid, * FROM pg_language UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_language');
CREATE VIEW validator.pg_rewrite_all AS SELECT gp_segment_id, oid, * FROM pg_rewrite UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_rewrite');
CREATE VIEW validator.pg_trigger_all AS SELECT gp_segment_id, oid, * FROM pg_trigger UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_trigger');
CREATE VIEW validator.pg_cast_all AS SELECT gp_segment_id, oid, * FROM pg_cast UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_cast');
CREATE VIEW validator.pg_namespace_all AS SELECT gp_segment_id, oid, * FROM pg_namespace UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_namespace');
CREATE VIEW validator.pg_conversion_all AS SELECT gp_segment_id, oid, * FROM pg_conversion UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_conversion');
CREATE VIEW validator.pg_tablespace_all AS SELECT gp_segment_id, oid, * FROM pg_tablespace UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_tablespace');
CREATE VIEW validator.pg_resqueue_all AS SELECT gp_segment_id, oid, * FROM pg_resqueue UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_resqueue');
CREATE VIEW validator.pg_resourcetype_all AS SELECT gp_segment_id, oid, * FROM pg_resourcetype UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_resourcetype');
CREATE VIEW validator.pg_partition_all AS SELECT gp_segment_id, oid, * FROM pg_partition UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_partition');
CREATE VIEW validator.pg_partition_rule_all AS SELECT gp_segment_id, oid, * FROM pg_partition_rule UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_partition_rule');
CREATE VIEW validator.pg_database_all AS SELECT gp_segment_id, oid, * FROM pg_database UNION ALL SELECT gp_segment_id, oid, * FROM gp_dist_random('pg_database');

------------------
-- pg_class_lookup
------------------
CREATE VIEW validator.temp_pg_class_toast AS
  SELECT 
    r1.*, coalesce(r3.relname || '_toast_index', r2.relname || '_toast') as basename
  FROM
    validator.pg_class_all r1
    LEFT JOIN validator.pg_class_all r2 on (r1.gp_segment_id = r2.gp_segment_id and (r1.oid = r2.reltoastidxid or r1.oid = r2.reltoastrelid))
    LEFT JOIN validator.pg_class_all r3 on (r2.gp_segment_id = r3.gp_segment_id and r2.oid = r3.reltoastrelid)
  WHERE r1.relnamespace = 99;
CREATE VIEW validator.temp_pg_class_ao AS
  SELECT 
    r1.*, coalesce(r3.relname || '_ao_seg_index', r2.relname || '_ao_seg') as basename
  FROM
    validator.pg_class_all r1
    LEFT JOIN validator.pg_class_all r2 on (r1.gp_segment_id = r2.gp_segment_id and (r1.oid = r2.relaosegidxid or r1.oid = r2.relaosegrelid))
    LEFT JOIN validator.pg_class_all r3 on (r2.gp_segment_id = r3.gp_segment_id and r2.oid = r3.relaosegrelid)
  WHERE r1.relnamespace = 6104;
CREATE VIEW validator.temp_pg_class_bitmap AS
  SELECT
    r1.*, r2.relname || '_bm' || (case when r1.relkind = 'i' then '_index' else '' end) as basename
  FROM
    validator.pg_class_all r1
    left join validator.pg_depend_all d on (r1.gp_segment_id = d.gp_segment_id and r1.oid = d.objid and d.deptype = 'i')
    left join validator.pg_class_all r2 on (r1.gp_segment_id = r2.gp_segment_id and r2.oid = d.refobjid)
  WHERE r1.relnamespace = 3012;
CREATE VIEW validator.temp_pg_class_everything_else AS
  SELECT
    r1.*,
    -- Rename implicit index to "implicit_index"
    case when (exists (select * from validator.pg_depend_all d
                          where r1.gp_segment_id = d.gp_segment_id 
                          and r1.relkind ='i'
                          and d.classid = 'pg_class'::regclass
                          and d.objid = r1.oid
                          and d.objsubid = 0
                          and d.refclassid = 'pg_constraint'::regclass
                          and d.refobjsubid = 0
                          and d.deptype = 'i')) then
      'implicit_index'
    else
      r1.relname
    end as basename
  FROM 
    validator.pg_class_all r1
  WHERE r1.relnamespace not in (99, 3012, 6104);  -- toast, bitmap, aoseg
CREATE VIEW validator.temp_pg_class AS
SELECT
  gp_segment_id,
  oid, 
  coalesce(basename, relname) as relname,
  relnamespace,
  reltype,
  relowner,
  relam,
  relfilenode,
  reltablespace,
  relpages,
  reltuples,
  reltoastrelid,
  reltoastidxid,
  relaosegrelid,
  relaosegidxid,
  relhasindex,
  relisshared,
  relkind,
  relstorage,
  relnatts,
  relchecks,
  reltriggers,
  relukeys,
  relfkeys,
  relrefs,
  relhasoids,
  relhaspkey,
  relhasrules,
  relhassubclass,
  relfrozenxid,
  relacl,
  reloptions
FROM
(
    SELECT * FROM validator.temp_pg_class_toast
    UNION ALL
    SELECT * FROM validator.temp_pg_class_ao
    UNION ALL
    SELECT * FROM validator.temp_pg_class_bitmap
    UNION ALL
    SELECT * FROM validator.temp_pg_class_everything_else
) u;
INSERT INTO validator.pg_class_lookup SELECT * FROM validator.temp_pg_class;

-----------------
-- pg_type_lookup
-----------------
CREATE VIEW validator.temp_pg_type AS
SELECT
  t.gp_segment_id,
  t.oid,
  coalesce(r.relname, t.typname) as typname,
  t.typnamespace,
  t.typowner,
  t.typlen,
  t.typbyval,
  t.typtype,
  t.typisdefined,
  t.typdelim,
  t.typrelid,
  t.typelem,
  t.typinput,
  t.typoutput,
  t.typreceive,
  t.typsend,
  t.typanalyze,
  t.typalign,
  t.typstorage,
  t.typnotnull,
  t.typbasetype,
  t.typtypmod,
  t.typndims,
  t.typdefaultbin,
  t.typdefault
FROM validator.pg_type_all t
LEFT JOIN validator.pg_class_lookup r on (t.gp_segment_id = r.orig_gp_segment_id and t.oid = r.reltype);
INSERT INTO validator.pg_type_lookup SELECT * FROM validator.temp_pg_type;

----------------
-- pg_oid_lookup
----------------
CREATE VIEW validator.temp_pg_oid_lookup AS
SELECT * FROM
  (select gp_segment_id, oid, 'pg_authid' as catname, 0 as nspoid, rolname from validator.pg_authid_all
   union all
   select orig_gp_segment_id, oid, 'pg_type' as catname, typnamespace, typname from validator.pg_type_lookup
   union all
   select gp_segment_id, oid, 'pg_proc' as catname, pronamespace, proname from validator.pg_proc_all
   union all
   select orig_gp_segment_id, oid, 'pg_class' as catname, relnamespace, relname from validator.pg_class_lookup
   union all
   select d.gp_segment_id, d.oid, 'pg_attrdef' as catname, r.relnamespace, r.relname || '.' || a.attname
       from validator.pg_attrdef_all d
       left outer join validator.pg_class_lookup r on (d.gp_segment_id = r.orig_gp_segment_id and d.adrelid = r.oid)
       left outer join validator.pg_attribute_all a on (d.gp_segment_id = a.gp_segment_id and d.adrelid = a.attrelid and d.adnum = a.attnum)
   union all
   select gp_segment_id, oid, 'pg_constraint' as catname, connamespace, conname from validator.pg_constraint_all
   union all
   select gp_segment_id, oid, 'pg_operator' as catname, oprnamespace, oprname from validator.pg_operator_all
   union all
   select gp_segment_id, oid, 'pg_opclass' as catname, opcnamespace, opcname from validator.pg_opclass_all
   union all
   select gp_segment_id, oid, 'pg_am' as catname, 0, amname from validator.pg_am_all
   union all
   select gp_segment_id, oid, 'pg_language' as catname, 0, lanname from validator.pg_language_all
   union all
   select w.gp_segment_id, w.oid, 'pg_rewrite' as catname, r.relnamespace,
           r.relname || '.' || w.ev_attr::text || '_' || w.rulename
       from validator.pg_rewrite_all w
       left outer join validator.pg_class_lookup r on (w.gp_segment_id = r.orig_gp_segment_id and w.ev_class = r.oid)
   union all
   select t.gp_segment_id, t.oid, 'pg_trigger' as catname, r.relnamespace, r.relname || '.' || tgname
       from validator.pg_trigger_all t
       left outer join validator.pg_class_lookup r on (t.gp_segment_id = r.orig_gp_segment_id and t.tgrelid = r.oid)
   union all
   select c.gp_segment_id, c.oid, 'pg_cast' as catname, a.typnamespace, a.typname || ' => ' || b.typname
       from validator.pg_cast_all c
       left outer join validator.pg_type_lookup a on (c.gp_segment_id = a.orig_gp_segment_id and a.oid = c.castsource)
       left outer join validator.pg_type_lookup b on (c.gp_segment_id = b.orig_gp_segment_id and b.oid = c.castsource)
   union all
   select gp_segment_id, oid, 'pg_namespace' as catname, 0, nspname from validator.pg_namespace_all
   union all
   select gp_segment_id, oid, 'pg_conversion' as catname, connamespace, conname from validator.pg_conversion_all
   union all
   select gp_segment_id, oid, 'pg_tablespace' as catname, 0, spcname from validator.pg_tablespace_all
   union all
   select gp_segment_id, oid, 'pg_resourcetype' as catname, 0, resname from validator.pg_resourcetype_all
   union all
   select gp_segment_id, oid, 'pg_resqueue' as catname, 0, rsqname from validator.pg_resqueue_all
   union all
   select p.gp_segment_id, p.oid, 'pg_partition' as catname, r.relnamespace, r.relname || '.partlevel_' || p.parlevel::text
       from validator.pg_partition_all p
       left outer join validator.pg_class_lookup r on (p.gp_segment_id = r.orig_gp_segment_id and p.parrelid = r.oid)
   union all
   select p.gp_segment_id, p.oid, 'pg_partition_rule' as catname, r.relnamespace, r.relname
       from validator.pg_partition_rule_all p
       left outer join validator.pg_class_lookup r on (p.gp_segment_id = r.orig_gp_segment_id and p.parchildrelid = r.oid)
   union all
   select gp_segment_id, oid, 'pg_database' as catname, 0, datname from validator.pg_database_all
) u ;
INSERT INTO validator.pg_oid_lookup SELECT * FROM validator.temp_pg_oid_lookup;


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
---------------------------------------- DEPRECATED --------------------------------------
-- DEPRECATED: AK: I'm deprecating these for reasons given above. This design decision
-- arises from QA-1933 and other revelations around the complexity of validator SQL.
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--
-- A view on pg_class that turns toast table, ao_segment, and bitmap names into something we can safely diff.
--   - We materialize it for efficiency reasons
--   - this is a messy query that is hard to write efficiently, union proves the best for large schemas.
--
INSERT INTO validator.pg_class_view 
SELECT
  oid, 
  coalesce(basename,relname) as relname,
  relnamespace,
  reltype,
  relowner,
  relam,
  relfilenode,
  reltablespace,
  relpages,
  reltuples,
  reltoastrelid,
  reltoastidxid,
  relaosegrelid,
  relaosegidxid,
  relhasindex,
  relisshared,
  relkind,
  relstorage,
  relnatts,
  relchecks,
  reltriggers,
  relukeys,
  relfkeys,
  relrefs,
  relhasoids,
  relhaspkey,
  relhasrules,
  relhassubclass,
  relfrozenxid,
  relacl,
  reloptions
FROM
(
  -- Everything not in toast, bitmap, or aoseg schemas
  SELECT
    r1.oid, r1.*,
    -- Rename implicit index to "implicit_index"
    case when (exists (select * from pg_depend d
                    where r1.relkind ='i'
                      and d.classid = 'pg_class'::regclass
                      and d.objid = r1.oid
                      and d.objsubid = 0
                      and d.refclassid = 'pg_constraint'::regclass
                      and d.refobjsubid = 0
                      and d.deptype = 'i')) then
      'implicit_index'
    else
      r1.relname
    end as basename
  FROM 
    pg_class r1
  WHERE r1.relnamespace not in (99, 3012, 6104)  -- toast, bitmap, aoseg
  UNION ALL
  -- Everything in Toast
  SELECT 
    r1.oid, r1.*, coalesce(r3.relname || '_toast_index', 
                           r2.relname || '_toast') as basename
  FROM
    pg_class r1
    LEFT JOIN pg_class r2 on (r1.oid = r2.reltoastidxid or r1.oid = r2.reltoastrelid)
    LEFT JOIN pg_class r3 on (r2.oid = r3.reltoastrelid)
  WHERE r1.relnamespace = 99
  UNION ALL
  -- Everything in AO segment
  SELECT 
    r1.oid, r1.*, coalesce(r3.relname || '_ao_seg_index', 
                           r2.relname || '_ao_seg') as basename
  FROM
    pg_class r1
    LEFT JOIN pg_class r2 on (r1.oid = r2.relaosegidxid or r1.oid = r2.relaosegrelid)
    LEFT JOIN pg_class r3 on (r2.oid = r3.relaosegrelid)
  WHERE r1.relnamespace = 6104
  UNION ALL
  -- Everything in Bitmap
  SELECT
    r1.oid, r1.*, r2.relname || '_bm' || 
                  (case when r1.relkind = 'i' then '_index' else '' end) as basename
  FROM
    pg_class r1
    left join pg_depend d on (r1.oid = d.objid and d.deptype = 'i')
    left join pg_class r2 on (r2.oid = d.refobjid)
  WHERE r1.relnamespace = 3012
) u;


INSERT INTO validator.pg_class_seg_view 
SELECT
  oid, 
  coalesce(basename,relname) as relname,
  relnamespace,
  reltype,
  relowner,
  relam,
  relfilenode,
  reltablespace,
  relpages,
  reltuples,
  reltoastrelid,
  reltoastidxid,
  relaosegrelid,
  relaosegidxid,
  relhasindex,
  relisshared,
  relkind,
  relstorage,
  relnatts,
  relchecks,
  reltriggers,
  relukeys,
  relfkeys,
  relrefs,
  relhasoids,
  relhaspkey,
  relhasrules,
  relhassubclass,
  relfrozenxid,
  relacl,
  reloptions
FROM
(
  -- Everything not in toast, bitmap, or aoseg schemas
  SELECT
    r1.oid, r1.*,
    -- Rename implicit index to "implicit_index"
    case when (exists (select * from pg_depend d
                    where r1.relkind ='i'
                      and d.classid = 'pg_class'::regclass
                      and d.objid = r1.oid
                      and d.objsubid = 0
                      and d.refclassid = 'pg_constraint'::regclass
                      and d.refobjsubid = 0
                      and d.deptype = 'i')) then
      'implicit_index'
    else
      r1.relname
    end as basename
  FROM 
    pg_class r1
  WHERE r1.relnamespace not in (99, 3012, 6104)  -- toast, bitmap, aoseg
  UNION ALL
  -- Everything in Toast
  SELECT 
    r1.oid, r1.*, coalesce(r3.relname || '_toast_index', 
                           r2.relname || '_toast') as basename
  FROM
    pg_class r1
    LEFT JOIN pg_class r2 on (r1.oid = r2.reltoastidxid or r1.oid = r2.reltoastrelid)
    LEFT JOIN pg_class r3 on (r2.oid = r3.reltoastrelid)
  WHERE r1.relnamespace = 99
  UNION ALL
  -- Everything in AO segment
  SELECT 
    r1.oid, r1.*, coalesce(r3.relname || '_ao_seg_index', 
                           r2.relname || '_ao_seg') as basename
  FROM
    pg_class r1
    LEFT JOIN pg_class r2 on (r1.oid = r2.relaosegidxid or r1.oid = r2.relaosegrelid)
    LEFT JOIN pg_class r3 on (r2.oid = r3.relaosegrelid)
  WHERE r1.relnamespace = 6104
  UNION ALL
  -- Everything in Bitmap
  SELECT
    r1.oid, r1.*, r2.relname || '_bm' || 
                  (case when r1.relkind = 'i' then '_index' else '' end) as basename
  FROM
    pg_class r1
    left join pg_depend d on (r1.oid = d.objid and d.deptype = 'i')
    left join pg_class r2 on (r2.oid = d.refobjid)
  WHERE r1.relnamespace = 3012
) u;

--
-- A view on pg_type that turns toast table names into something we can safely diff.
--   - We materialize it for efficiency reasons
--
INSERT INTO validator.pg_type_view
SELECT
  t.oid,
  coalesce(r.relname, t.typname) as typname,
  t.typnamespace,
  t.typowner,
  t.typlen,
  t.typbyval,
  t.typtype,
  t.typisdefined,
  t.typdelim,
  t.typrelid,
  t.typelem,
  t.typinput,
  t.typoutput,
  t.typreceive,
  t.typsend,
  t.typanalyze,
  t.typalign,
  t.typstorage,
  t.typnotnull,
  t.typbasetype,
  t.typtypmod,
  t.typndims,
  t.typdefaultbin,
  t.typdefault
FROM pg_type t
LEFT JOIN validator.pg_class_view r on (t.oid = r.reltype)
;

INSERT INTO validator.pg_type_seg_view
SELECT
  t.oid,
  coalesce(r.relname, t.typname) as typname,
  t.typnamespace,
  t.typowner,
  t.typlen,
  t.typbyval,
  t.typtype,
  t.typisdefined,
  t.typdelim,
  t.typrelid,
  t.typelem,
  t.typinput,
  t.typoutput,
  t.typreceive,
  t.typsend,
  t.typanalyze,
  t.typalign,
  t.typstorage,
  t.typnotnull,
  t.typbasetype,
  t.typtypmod,
  t.typndims,
  t.typdefaultbin,
  t.typdefault
FROM pg_type t
LEFT JOIN validator.pg_class_seg_view r on (t.oid = r.reltype)
;


--
-- A view unioning all catalog tables with OIDS
--   - We materialize it for efficiency reasons
--
INSERT INTO validator.pg_oid_tables
SELECT * FROM
  (select 'pg_authid' as catname, 0 as nspoid, rolname as objname, oid
   from pg_authid
   union all
   select 'pg_type' as catname, typnamespace, typname, oid 
   from validator.pg_type_view
   union all
   select 'pg_proc' as catname, pronamespace, proname, oid 
   from pg_proc
   union all
   select 'pg_class' as catname, relnamespace, relname, oid 
   from validator.pg_class_view
   union all
   select 'pg_attrdef' as catname, r.relnamespace, r.relname || '.' || a.attname, d.oid
   from pg_attrdef d
   left outer join validator.pg_class_view r on (d.adrelid = r.oid)
   left outer join pg_attribute a on (d.adrelid = a.attrelid and d.adnum = a.attnum)
   union all
   select 'pg_constraint' as catname, connamespace, conname, oid 
   from pg_constraint
   union all
   select 'pg_operator' as catname, oprnamespace, oprname, oid 
   from pg_operator
   union all
   select 'pg_opclass' as catname, opcnamespace, opcname, oid 
   from pg_opclass
   union all
   select 'pg_am' as catname, 0, amname, oid from pg_am
   union all
   select 'pg_language' as catname, 0, lanname, oid from pg_language
   union all
   select 'pg_rewrite' as catname, r.relnamespace, 
           r.relname || '.' || w.ev_attr::text || '_' || w.rulename, w.oid 
   from pg_rewrite w
   left outer join validator.pg_class_view r on (w.ev_class = r.oid)
   union all
   select 'pg_trigger' as catname, r.relnamespace, r.relname || '.' || tgname, t.oid 
   from pg_trigger t
   left outer join validator.pg_class_view r on (t.tgrelid = r.oid)
   union all
   select 'pg_cast' as catname, a.typnamespace, a.typname || ' => ' || b.typname, c.oid
   from pg_cast c
   left outer join pg_type a on (a.oid = c.castsource)
   left outer join pg_type b on (b.oid = c.castsource)
   union all
   select 'pg_namespace' as catname, 0, nspname, oid from pg_namespace
   union all
   select 'pg_conversion' as catname, connamespace, conname, oid from pg_conversion
   union all
   select 'pg_tablespace' as catname, 0, spcname, oid from pg_tablespace
   union all
   select 'pg_resqueue' as catname, 0, rsqname, oid from pg_resqueue
   union all
   select 'pg_partition' as catname, r.relnamespace, r.relname || '.partlevel_' || p.parlevel::text, p.oid
   from pg_partition p
   left outer join validator.pg_class_view r on (p.parrelid = r.oid)
   union all
   select 'pg_partition_rule' as catname, r.relnamespace, r.relname, p.oid 
   from pg_partition_rule p
   left outer join validator.pg_class_view r on (p.parchildrelid = r.oid)
   union all
   select 'pg_database' as catname, 0, datname, oid from pg_database
) u
;


INSERT INTO validator.pg_oid_tables_seg
SELECT * FROM
  (select 'pg_authid' as catname, 0 as nspoid, rolname as objname, oid
   from pg_authid
   union all
   select 'pg_type' as catname, typnamespace, typname, oid
   from validator.pg_type_seg_view
   union all
   select 'pg_proc' as catname, pronamespace, proname, oid
   from pg_proc
   union all
   select 'pg_class' as catname, relnamespace, relname, oid
   from validator.pg_class_seg_view
   union all
   select 'pg_attrdef' as catname, r.relnamespace, r.relname || '.' || a.attname, d.oid
   from pg_attrdef d
   left outer join validator.pg_class_view r on (d.adrelid = r.oid)
   left outer join pg_attribute a on (d.adrelid = a.attrelid and d.adnum = a.attnum)
   union all
   select 'pg_constraint' as catname, connamespace, conname, oid
   from pg_constraint
   union all
   select 'pg_operator' as catname, oprnamespace, oprname, oid
   from pg_operator
   union all
   select 'pg_opclass' as catname, opcnamespace, opcname, oid
   from pg_opclass
   union all
   select 'pg_am' as catname, 0, amname, oid from pg_am
   union all
   select 'pg_language' as catname, 0, lanname, oid from pg_language
   union all
   select 'pg_rewrite' as catname, r.relnamespace,
           r.relname || '.' || w.ev_attr::text || '_' || w.rulename, w.oid
   from pg_rewrite w
   left outer join validator.pg_class_view r on (w.ev_class = r.oid)
   union all
   select 'pg_trigger' as catname, r.relnamespace, r.relname || '.' || tgname, t.oid
   from pg_trigger t
   left outer join validator.pg_class_view r on (t.tgrelid = r.oid)
   union all
   select 'pg_cast' as catname, a.typnamespace, a.typname || ' => ' || b.typname, c.oid
   from pg_cast c
   left outer join pg_type a on (a.oid = c.castsource)
   left outer join pg_type b on (b.oid = c.castsource)
   union all
   select 'pg_namespace' as catname, 0, nspname, oid from pg_namespace
   union all
   select 'pg_conversion' as catname, connamespace, conname, oid from pg_conversion
   union all
   select 'pg_tablespace' as catname, 0, spcname, oid from pg_tablespace
   union all
   select 'pg_resourcetype' as catname, 0, resname, oid from pg_resourcetype
   union all
   select 'pg_resqueue' as catname, 0, rsqname, oid from pg_resqueue
   union all
   select 'pg_partition' as catname, r.relnamespace, r.relname || '.partlevel_' || p.parlevel::text, p.oid
   from pg_partition p
   left outer join validator.pg_class_view r on (p.parrelid = r.oid)
   union all
   select 'pg_partition_rule' as catname, r.relnamespace, r.relname, p.oid
   from pg_partition_rule p
   left outer join validator.pg_class_view r on (p.parchildrelid = r.oid)
   union all
   select 'pg_database' as catname, 0, datname, oid from pg_database
) u
;

