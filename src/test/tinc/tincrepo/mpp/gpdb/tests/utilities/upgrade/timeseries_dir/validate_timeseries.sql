-- weighted moving functions
drop table if exists sale; create table sale (pn int);
insert into sale (pn) values (100);
insert into sale (pn) values (100);
insert into sale (pn) values (200);
insert into sale (pn) values (200);
insert into sale (pn) values (300);
insert into sale (pn) values (400);
insert into sale (pn) values (400);
insert into sale (pn) values (500);
insert into sale (pn) values (500);
insert into sale (pn) values (600);
insert into sale (pn) values (700);
insert into sale (pn) values (800);



select pn,
       wm_avg(pn, array[0.1, 0.2, 0.7], 0) over(order by pn),
       wm_avg(pn::float, array[0.1, 0.2, 0.7], 0) over(order by pn)
from sale;
select pn,
       wm_avg(pn::float, array[0.2, 0.4], -2) over(order by pn),
       wm_avg(pn::float, array[0.2, 0.4], -1) over(order by pn),
       wm_avg(pn::float, array[0.2, 0.4], +1) over(order by pn),
       wm_avg(pn::float, array[0.2, 0.4], +2) over(order by pn)
from sale;
select pn,
       wm_var_pop(pn, array[0.1, 0.2, 0.7], 0) over (order by pn),
       wm_var_samp(pn, array[0.1, 0.2, 0.7], 0) over(order by pn),
       wm_var_pop(pn::float, array[0.1, 0.2, 0.7], 0) over (order by pn),
       wm_var_samp(pn::float, array[0.1, 0.2, 0.7], 0) over(order by pn)
from sale;
select pn,
       wm_stddev_pop(pn::float, array[0.2, 0.4], -2) over(order by pn),
       wm_stddev_pop(pn::float, array[0.2, 0.4], -1) over(order by pn),
       wm_stddev_pop(pn::float, array[0.2, 0.4], +1) over(order by pn),
       wm_stddev_pop(pn::float, array[0.2, 0.4], +2) over(order by pn)
from sale;
select wm_avg(a, '{0.2}'::numeric[], 0) over (order by a)
from (values('NaN'::numeric),(0.1)) s(a);
select wm_avg(a, '{0.2, 0.3}'::numeric[], 0) over (order by a)
from (values(NULL::numeric),(0.1)) s(a);

select wm_avg(pn, ary, 3) over (order by pn)
from sale, (values('{0.1, 0.2}'::float[])) s(ary);
select wm_avg(pn, '{0.1,0.2}'::float[], ofs) over (order by pn)
from sale, (values(3)) s(ofs);
select wm_var_pop(pn, array[0.1, 0.9], 0) over
    (order by pn rows between 1 preceding and current row) from sale;


drop table if exists gapinput cascade; -- ignore
create table gapinput
(
	a int,
	b int,
	pk1 int,
	pk2 int,
	sk bigint
)
distributed randomly;

-- NULL partitioning key
delete from gapinput; -- ignore
insert into gapinput values
     (0, 0, NULL, NULL, 7);

select pk1, pk2, qk, sk, b
from gapinput
sequence q as (
        partition by pk1, pk2
        order by sk
        key qk every 2 between 4 and 8 )
order by pk1, pk2, qk, sk, b;

delete from gapinput; -- ignore
insert into gapinput values
     (0, 0, -1, -1, 1),
     (1, 0, -1, -1, 3),
     (2, 0, -1, -1, 5),
     (3, 0, -1, -1, 6),
     (4, 0, -1, -1, 9),
     (5, 0, -1, -1, 11),
     (6, 0, -1, -1, 13),
     (7, 0, -1, -2, 2),
     (8, 0, -1, -2, 4),
     (9, 0, -1, -3, 7),
     (10, 0, -1, -3, 10),
     (11, 0, -1, -3, 12),
     (12, 0, -1, -4, 14);

-- Sub-query
select sum((select si from gapinput
	sequence q as (order by sk key si every 3 between 2 and 8)
	order by si limit 1));

-- CSQ
select a, 1 + (select qk + t.a from gapinput
	sequence q as (order by sk key qk every 3 between 2 and 8)
	order by qk limit 1)
from gapinput t order by a;

select a, 1 + (select qk from gapinput
	where a = t.a sequence q as (order by sk key qk every 2 between 4 and 8)
	order by qk limit 1)
from gapinput t order by a;

select a, 1 + (select qk from gapinput
	sequence q as (order by sk key qk every t.a + 1 between 4 and 8)
	order by qk limit 1)
from gapinput t order by a;

select a, 1 + (select qk from gapinput
	sequence q as (order by sk key qk every 2 between t.a and 4)
	order by qk limit 1)
from gapinput t order by a;

select a, 1 + (select qk from gapinput
	sequence q as (order by sk key qk every 2 between 0 and t.a)
	order by qk limit 1)
from gapinput t order by a;

-- lead/lag/first_value/last_value
select pk1, a, b, sk, qk, lead(qk) over (q), lag(qk) over (q),
	first_value(si) over(q), last_value(qk) over (q)
from gapinput
sequence q as (partition by pk1 order by sk key qk every 3 between 2 and 6);

-- CTAS
create temp table tempgap as
select t1.sk, rank() over(q), qk
from gapinput t1 inner join gapinput t2 on t1.a = t2.b
sequence q as (order by t1.sk key qk every 1 between 4 and 8);
select * from tempgap;
drop table tempgap;

-- distinct
select distinct a, b, sk, qk from gapinput
sequence q as (order by sk key qk every 2 between 4 and 8);
select distinct on (qk) a, b, qk from gapinput
sequence q as (order by sk key qk every 2 between 4 and 8);

-- prepare
prepare x (int) as
select a, b, sk, qk from gapinput
sequence q as (order by sk key qk every $1 between 4 and 8);
execute x(2);
execute x(-1);
deallocate x;
prepare x (int) as
select a, b, sk, qk from gapinput
sequence q as (order by sk key qk every 1 between $1 and 8);
execute x(4);
deallocate x;
prepare x (int, int) as
select a, b, sk, qk from gapinput
sequence q as (order by sk key qk every 1 between $1 and $2);
execute x(4, 8);
execute x(8, 4);
deallocate x;

-- on view
create view gapinputview as select pk1, pk2, a, b, sk from gapinput where a  < 5;
select a, b, sk, qk from gapinputview
sequence q as (order by sk key qk every 1 between 4 and 8);

-- null order by
select a, b, sk, qk
from(values(2, 20, null::int))as foo (a, b, sk)
sequence q as (order by sk key qk every 1 between 4 and 8);

-- functions
CREATE OR REPLACE FUNCTION mygapfunc (evry int,s int, e int)
RETURNS SETOF record AS $$
  	select t1.sk, rank() over(q), qk
	from gapinput t1 inner join gapinput t2 on t1.a = t2.b
	sequence q as (order by t1.sk key qk every $1 between $2 and $3);
$$ LANGUAGE SQL;
select mygapfunc(1,4,8);
drop function mygapfunc(evry integer, s integer, e integer);
    
-- partition
create table gapinput_partition 
( like gapinput ) partition by range(a) ( start (0) end (20) every (2));
insert into gapinput_partition select * from gapinput;
select pk1, a, b, sk, qk lead(sk) over (q), lag(qk) over (q),
	first_value(sk) over(q), last_value(qk) over (q)
from gapinput_partition
sequence q as (partition by pk1 order by sk key qk every 3 between 2 and 6);
drop table gapinput_partition;

-- index
set enable_seqscan=off;
set enable_bitmapscan=off;
set enable_indexscan=on;
create index gapinput_index on gapinput (a);
select t1.sk, rank() over(q), qk
from gapinput t1 inner join gapinput t2 on t1.a = t2.b
sequence q as (order by t1.sk key qk every 1 between 4 and 8);
drop index gapinput_index;

-- IGNORE NULLS for lead and lag
create table ignull(i numeric, j numeric, k numeric) distributed by(i);
copy ignull from stdin;
1	\N	1
2	\N	1
3	3	1
4	4	1
5	\N	2
6	6	2
7	7	2
8	\N	2
9	\N	2
10	\N	3
\.

select i, j, lead(j) ignore nulls over (order by i) as f1,
	lead(j, 0) ignore nulls over (order by i) as f2,
	lead(j, 2) ignore nulls over (order by i) as f3,
	lead(j, 0, -1) ignore nulls over (order by i) as f4,
	lead(j, i::bigint) ignore nulls over (order by i) as f5
	from ignull;

select i, j, lag(j) ignore nulls over (order by i) as l1,
	lag(j, 0) ignore nulls over (order by i) as l2,
	lag(j, 2) ignore nulls over (order by i) as l3,
	lag(j, 0, -1) ignore nulls over (order by i) as l4,
	lag(j, 10-i::bigint) ignore nulls over (order by i) as l5
	from ignull;

select k, i, j, lead(j) ignore nulls over (partition by k order by i) as f10,
	lag(j) ignore nulls over (partition by k order by i) as l10
	from ignull order by k, i;
