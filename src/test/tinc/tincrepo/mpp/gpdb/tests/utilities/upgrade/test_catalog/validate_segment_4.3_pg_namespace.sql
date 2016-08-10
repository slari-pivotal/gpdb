select oid, * from gp_dist_random('pg_namespace') where nspname<>'gp_toolkit' and oid<10000 order by oid;
