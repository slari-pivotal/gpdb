--
-- pg_partition
--

\d pg_partition

-- unnest the parclass array to resolve oids
select
  n1.nspname,
  r.relname,
  p.parkind,
  p.parlevel,
  p.paristemplate,
  p.parnatts,
  p.paratts,
  p.i,
  n2.nspname as opcnamespace,
  o.opcname  as opcname
from (select *, generate_series(0, array_upper(parclass,1)) as i from pg_partition) p
left join pg_class r on (p.parrelid = r.oid)
left join pg_namespace n1 on (r.relnamespace = n1.oid)
left join pg_opclass o on (p.parclass[p.i] = o.oid)
left join pg_namespace n2 on (o.opcnamespace = n2.oid)
order by n1.nspname, r.relname, p.parlevel, i;