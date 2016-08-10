--
-- pg_language
--   ACLs checked in aclcheck
--

\d pg_language

select 
  lanname,
  lanispl,
  lanpltrusted,
  lanplcallfoid::regproc,
  lanvalidator::regproc
from pg_language
order by lanname;