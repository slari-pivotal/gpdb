-- 
-- Check the procedural tablespace table
--  * Must lookup the username in the pg_user table
--  * ACL lists will be compared in the aclcheck test
--
\d pg_tablespace

select a.spcname, a.spclocation, a.spcprilocations, spcmirlocations
from pg_tablespace a
join pg_user b on (a.spcowner = b.usesysid)
order by a.spcname;
