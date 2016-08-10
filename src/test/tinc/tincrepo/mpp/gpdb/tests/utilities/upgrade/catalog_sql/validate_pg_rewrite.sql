--
-- pg_rewrite
--

\d pg_rewrite

-- The two columns ev_qual and ev_action are not directly dumpable,
-- instead we use pg_get_viewdef/pg_get_ruledef to extract the info.
select 
  n.nspname,
  r.relname,
  w.ev_attr,
  w.rulename, 
  w.ev_type,
  w.is_instead,
  case when w.rulename = '_RETURN' 
       then pg_get_viewdef(w.ev_class)
       else pg_get_ruledef(w.oid) 
  end as definition
from pg_rewrite w
left outer join pg_class r on (w.ev_class = r.oid)
left outer join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname, w.ev_attr, w.rulename;