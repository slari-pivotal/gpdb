-- @product_version gpdb: [4.3.2.1 -]
-- Validate that pg_toast entry for visimap is blank
select count(*) from pg_class where oid=(select visimaprelid from pg_appendonly where relid = (select oid from pg_class where relname='ao_drop')) and reltoastrelid = 0;
select count(*) from pg_class where oid=(select visimaprelid from pg_appendonly where relid = (select oid from pg_class where relname='aocs_drop')) and reltoastrelid = 0;

-- Validate that pg_depend catalog table has an entry for visimap
select count(*) from pg_depend where  objid =(select visimaprelid from pg_appendonly where relid =(select oid from pg_class where relname='ao_drop'));
select count(*) from pg_depend where  objid =(select visimaprelid from pg_appendonly where relid =(select oid from pg_class where relname='aocs_drop'));
drop table ao_drop;
drop table aocs_drop;

-- find unattached visimaps
SELECT relname FROM pg_catalog.pg_class WHERE relname LIKE 'pg_aovisimap%' AND relkind = 'm' AND relnamespace=6104 AND oid NOT IN (SELECT visimaprelid FROM pg_catalog.pg_appendonly);

-- find pg_depend inconsistencies
SELECT relid::regclass, visimaprelid::regclass, relid, visimaprelid FROM pg_catalog.pg_appendonly WHERE visimaprelid NOT IN (SELECT objid FROM pg_catalog.pg_depend, pg_catalog.pg_appendonly WHERE pg_depend.refobjid = pg_appendonly.relid);

-- find superious toast
SELECT reltoastrelid, reltoastrelid::regclass, oid FROM pg_catalog.pg_class WHERE reltoastrelid > 0 AND oid IN (SELECT visimaprelid FROM pg_catalog.pg_appendonly);
CREATE TABLE ao_drop (a INT, b INT) WITH (appendonly=true);
CREATE TABLE aocs_drop (a INT, b INT) WITH (appendonly=true, orientation=column);
vacuum freeze;


