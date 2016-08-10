--
-- Access methods
--

\d pg_amop

select 
  c.opcname as amopcla,
  m.amopstrategy,
  m.amopreqcheck,
  o.oprname
from pg_amop m
left join pg_opclass c on (c.oid = m.amopclaid)
left join pg_operator o on (o.oid = m.amopopr)
order by c.opcname, m.amopstrategy, m.amopreqcheck, o.oprname;

