--
-- Check pg_filespace and pg_filespace_entry
--

\d pg_filespace
\d pg_filespace_entry

-- QA-1971  
--
-- In order to understand the need for this function, we need to understand the
-- context in which it will be invoked. Broadly speaking, during upgrade testing,
-- we will need to perform the same tasks against a FRESH database as an UPGRADED
-- database; this generally implies that the catalogs of these databases should
-- match, a fact we try to demand through validator SQL. 
--
-- For filespace testing, unfortunately, this is not strictly possible. 
-- The UPGRADED and FRESH servers cannot put their filespaces in the same physical 
-- locations. In order to rectify this, we permit some differences in the 
-- fselocations through the use of canonicalize_filespace().
CREATE OR REPLACE FUNCTION validator.canonicalize_filespace(fselocation text) RETURNS text AS $$
    SELECT regexp_replace(
                regexp_replace($1,
                               '_upgrade|_new',
                               '_UPGRADED_OR_NEW',
                               'g'),
                E'\\d+\\.\\d+\\.\\d+\\.\\d+|\\d+\\.\\d+',
                'GPDB_VERSION')
$$ LANGUAGE SQL;

select fs.fsname,
       u.usename,
       fse.fsedbid,
       validator.canonicalize_filespace(fse.fselocation)
from pg_filespace fs,
     pg_filespace_entry fse,
     pg_user u
where fs.fsowner = u.usesysid
  and fs.oid = fse.fsefsoid
  and fs.fsname != 'pg_system'
order by 1,2,3,4;
