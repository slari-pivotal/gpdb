--
-- check pg_autovacuum
--

\d pg_autovacuum

SELECT
  n.nspname,
  r.relname,
  v.enabled,
  v.vac_base_thresh,
  v.vac_scale_factor,
  v.anl_base_thresh,
  v.anl_scale_factor,
  v.vac_cost_delay,
  v.vac_cost_limit,
  v.freeze_min_age,
  v.freeze_max_age
FROM pg_autovacuum v
left join validator.pg_class_view r on (r.oid = v.vacrelid)
left join pg_namespace n on (n.oid = r.relnamespace)
order by n.nspname, r.relname;