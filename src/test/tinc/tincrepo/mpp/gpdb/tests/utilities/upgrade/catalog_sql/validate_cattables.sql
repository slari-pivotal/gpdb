--
-- This is a list of catalog tables.
--   * They should all have OIDS < 10000
--   * If new catalog tables are added we need to add more validation
--     scripts to check them.
--
select oid, relname 
from   pg_class 
where  relnamespace=11 and relkind='r' 
order by oid;
