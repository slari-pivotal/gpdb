--
-- pg_partition_encoding (Added in Rio)
--

\d pg_partition_encoding

select
  n.nspname,
  r.relname,
  a.parencattnum,
  a.parencattoptions,
  b.parkind,
  b.parlevel,
  b.parnatts
from pg_partition_encoding a
left join pg_partition b on (a.parencoid = b.oid)
left join pg_class r on (b.parrelid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname ;

-- Query segments (Does not return rows. Might have to remove this?)
select
  n.nspname,
  r.relname,
  a.parencattnum,
  a.parencattoptions,
  b.parkind,
  b.parlevel,
  b.parnatts
from pg_partition_encoding a
left join pg_partition b on (a.parencoid = b.oid)
left join pg_class r on (b.parrelid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname ;
