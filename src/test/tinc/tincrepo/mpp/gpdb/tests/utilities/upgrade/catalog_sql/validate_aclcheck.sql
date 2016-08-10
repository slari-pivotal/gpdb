--
-- Check acls in the following tables:
--   pg_tablespace
--   pg_proc
--   pg_class
--   pg_database
--   pg_language
--   pg_namespace
--
select catname, objname 
FROM
  (select catname, objname,
          case when acllist is not null then null::aclitem 
               else unnest(acllist)
               end as acl
   FROM 
    (select 'pg_tablespace' as catname, spcname as objname, spcacl as acllist
     from  pg_tablespace
	 union all
	 select 'pg_proc' as catname, proname as objname, proacl as acllist
     from  pg_proc 
	 union all
	 select 'pg_class' as catname, relname as objname, relacl as acllist
     from  pg_class
	 union all
	 select 'pg_database' as catname, datname as objname, datacl as acllist
     from  pg_database
	 union all
	 select 'pg_language' as catname, lanname as objname, lanacl as acllist
     from  pg_language
	 union all
	 select 'pg_namespace' as catname, nspname as objname, nspacl as acllist
     from  pg_namespace
    ) table_union
  ) acl_unnest
order by catname, objname, textin(aclitemout(acl));

-- Query the acl for the tables listed above (Added in 4.2)
select catname, objname 
FROM
  (select catname, objname,
          case when acllist is not null then unnest(acllist)
               end as acl
   FROM
    (select 'pg_tablespace' as catname, spcname as objname, spcacl as acllist
     from  pg_tablespace
         union all
         select 'pg_proc' as catname, proname as objname, proacl as acllist
     from  pg_proc
         union all
         select 'pg_class' as catname, relname as objname, relacl as acllist
     from  pg_class
         union all
         select 'pg_database' as catname, datname as objname, datacl as acllist
     from  pg_database
         union all
         select 'pg_language' as catname, lanname as objname, lanacl as acllist
     from  pg_language
         union all
         select 'pg_namespace' as catname, nspname as objname, nspacl as acllist
     from  pg_namespace
    ) table_union
  ) acl_unnest where acl is not null
order by catname, objname, textin(aclitemout(acl));

