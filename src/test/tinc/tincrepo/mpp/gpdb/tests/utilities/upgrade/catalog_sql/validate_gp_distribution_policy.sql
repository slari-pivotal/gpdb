--
-- gp_distribution_policy
--

\d gp_distribution_policy

select count(*) from gp_distribution_policy;

select
  n.nspname,
  r.relname,
  d.attrnums
from gp_distribution_policy d
left join validator.pg_class_view r on (d.localoid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname;