select oid, * from pg_namespace where nspname<>'gp_toolkit' and oid<10000 order by oid;
