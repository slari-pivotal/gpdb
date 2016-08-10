select oid, * from pg_constraint where oid < 10000 order by oid;
