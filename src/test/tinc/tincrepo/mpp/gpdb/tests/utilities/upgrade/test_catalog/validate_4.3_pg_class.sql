select oid, relname, relnamespace, relowner, reltype, relam, relfilenode, reltablespace from pg_class where oid < 10000 and reltype<10000 order by oid;
