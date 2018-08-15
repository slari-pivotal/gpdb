--
-- Extra GPDB tests on INSERT/UPDATE/DELETE RETURNING
--

CREATE TABLE returning_parttab (distkey int4, partkey int4, i int, t text)
DISTRIBUTED BY (distkey)
PARTITION BY RANGE (partkey) (START (1) END (10));

--
-- Test INSERT RETURNING with partitioning
--
insert into returning_parttab values (1, 1, 1, 'single insert') returning *;
insert into returning_parttab
select 1, g, g, 'multi ' || g from generate_series(1, 5) g
returning distkey, partkey, i, t;

-- Drop a column, and create a new partition. The new partition will not have
-- the dropped column, while in the old partition, it's still physically there,
-- just marked as dropped. Make sure the executor maps the columns correctly.
ALTER TABLE returning_parttab DROP COLUMN i;

alter table returning_parttab add partition newpart start (10) end (20);

insert into returning_parttab values (1, 10, 'single2 insert') returning *;
insert into returning_parttab select 2, g + 10, 'multi2 ' || g from generate_series(1, 5) g
returning distkey, partkey, t;

--
-- Test UPDATE/DELETE RETURNING with partitioning
--
update returning_parttab set partkey = 9 where partkey = 3 returning *;
update returning_parttab set partkey = 19 where partkey = 13 returning *;

-- update that moves the tuple across partitions (not supported)
update returning_parttab set partkey = 18 where partkey = 4 returning *;

-- delete
delete from returning_parttab where partkey = 14 returning *;


-- Check table contents, to be sure that all the commands did what they claimed.
select * from returning_parttab;