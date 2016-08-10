select * from gp_dist_random('pg_attribute') where attrelid<10000 order by attrelid, attnum;
