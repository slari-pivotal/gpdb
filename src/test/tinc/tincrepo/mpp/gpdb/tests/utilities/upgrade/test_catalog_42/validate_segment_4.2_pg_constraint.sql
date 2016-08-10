select oid, * from gp_dist_random('pg_constraint') where oid < 10000 order by oid;
