--
-- Check pg_resqueuecapability
--

\d pg_resqueuecapability

select r.rsqname, c.restypid, c.ressetting
from pg_resqueue r,
     pg_resqueuecapability c
where c.resqueueid = r.oid
order by 1,2,3;

select r.rsqname, c.restypid, c.ressetting
from pg_resqueue r,
     pg_resqueuecapability c
where c.resqueueid = r.oid
order by 1,2,3;
