--
--  Check pg_depend - inter object dependency table
--

\d pg_depend

--
-- formulate diff-safe version of pg_depend
--
CREATE VIEW validator.pg_depend_view AS
SELECT
  d.gp_segment_id,
  d.deptype,
  l.catname, 
  n1.nspname,
  l.objname,
  d.objsubid,
  r.catname as refcatname,
  n2.nspname as refnspname,
  r.objname as refobjname,
  d.refobjsubid
FROM validator.pg_depend_all d
left outer join validator.pg_oid_lookup l on (d.gp_segment_id = l.orig_gp_segment_id and d.classid = l.catname::regclass and d.objid = l.oid)
left outer join validator.pg_oid_lookup r on (d.gp_segment_id = r.orig_gp_segment_id and d.refclassid = r.catname::regclass and d.refobjid = r.oid)
left outer join validator.pg_namespace_all n1 on (d.gp_segment_id = n1.gp_segment_id and l.nspoid = n1.oid)
left outer join validator.pg_namespace_all n2 on (d.gp_segment_id = n2.gp_segment_id and r.nspoid = n2.oid)
-- 4.2 hack; don't bother to check constraint dependency due to change in behavior
-- AK: use IS DISTINCT FROM so as not to flunk NULLs in this qualification
where l.catname IS DISTINCT FROM 'pg_constraint';

--
-- dump master's pg_depend content as seen through pg_depend_view
--
SELECT 
    deptype,
    catname,
    nspname,
    objname,
    objsubid,
    refcatname,
    refnspname,
    refobjname,
    refobjsubid 
FROM validator.pg_depend_view
WHERE gp_segment_id = -1
ORDER BY 1, 2, 3, 4, 5, 6, 7, 8, 9;

--
-- TODO: AK: We need a better way to capture invariant SQL.
-- 

-- Disclaimer: This invariant SQL must pass for the baseline SQL above to be indicative
-- of logical consistency.
--   - This particular query should return 0 rows.
--
--      Avoid dumping segment pg_depend data by asserting, within the database, that
-- the segments pg_depend is exactly equivalent. This is effectively a cross-consistency
-- check (a la gpcheckcat) coping with the fact that oids are not necessarily consistent from segment
-- to segment.
--      We produce a diff-safe version of pg_depend above for the purposes of validating
-- an UPGRADED pg_depend against the baseline FRESH pg_depend. Conveniently, this query is
-- also diff-safe with respect to the master and segments.
CREATE FUNCTION validator.num_segments() RETURNS bigint
    AS 'SELECT count(*) FROM gp_segment_configuration where content >= 0 and role = ''p'''
    LANGUAGE SQL STABLE;
CREATE VIEW validator.pg_depend_segments AS
    SELECT * FROM validator.pg_depend_view WHERE gp_segment_id != -1;
CREATE VIEW validator.pg_depend_corresponding_master_tuples AS
    SELECT fake_gp_segment_id,
           deptype,
           catname,
           nspname,
           objname,
           objsubid,
           refcatname,
           refnspname,
           refobjname,
           refobjsubid
    FROM validator.pg_depend_view
    CROSS JOIN generate_series(0, validator.num_segments()-1) fake_gp_segment_id
    WHERE gp_segment_id = -1;
-- dump extra segment tuples
SELECT * FROM validator.pg_depend_segments
EXCEPT ALL
SELECT * FROM validator.pg_depend_corresponding_master_tuples;
-- dump missing segment tuples
SELECT * FROM validator.pg_depend_corresponding_master_tuples
EXCEPT ALL
SELECT * FROM validator.pg_depend_segments;

--
-- Every dependency should have at least a refobj
--   - this should return 0 rows
--
-- Bug: MPP-5788 (aggregates with prefunc create bad dependency)
--
SELECT d.* FROM pg_depend d where d.refobjid = 0;
