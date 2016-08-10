--
-- Access methods
--

\d pg_amproc

select
  c.opcname as amopcla,
  t.typname,
  m.amprocnum,
  p.proname
from pg_amproc m
left join pg_opclass c on (c.oid = m.amopclaid)
left join pg_type t on (t.oid = m.amprocsubtype)
left join pg_proc p on (p.oid = m.amproc)
order by c.opcname, t.typname, m.amprocnum, p.proname;
