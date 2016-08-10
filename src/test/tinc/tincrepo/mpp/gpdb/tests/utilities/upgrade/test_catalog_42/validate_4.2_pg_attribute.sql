select * from pg_attribute where attrelid<10000 order by attrelid, attnum;
