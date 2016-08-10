select relname, relowner, relam, reltablespace from pg_class where relname not like 'pg_toast%' order by relname;
