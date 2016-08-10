--
-- pg_trigger
--

\d pg_trigger

select
  n.nspname as namespace,
  r.relname as relname,
  t.tgname,
  t.tgfoid::regproc,
  t.tgtype,
  t.tgenabled,
  t.tgisconstraint,
  t.tgconstrname,
  t.tgconstrrelid::regclass,
  t.tgdeferrable,
  t.tginitdeferred,
  t.tgnargs,
  t.tgattr,
  t.tgargs
from pg_trigger t
left join pg_class r on (t.tgrelid = r.oid)
left join pg_namespace n on (r.relnamespace = n.oid)
order by n.nspname, r.relname, t.tgname;