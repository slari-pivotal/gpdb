SELECT quote_ident(nspname) || '.' || quote_ident(relname)
FROM pg_class r join pg_namespace n on (relnamespace = n.oid)
where relkind = 'r' and nspname not like 'pg_%'
order by nspname, relname;