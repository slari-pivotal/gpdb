--
-- pg_constraint
--

\d pg_constraint

--
-- 3 queries: partition and non-partition, and non-table constraint
--
create or replace view rel_closure as
	select 
		coalesce(p.tableid, r.relid) as tableid,
		coalesce(p.tabledepth, 0) as tabledepth,
		r.relid::regclass as relid,
		coalesce(p.partdepth, 0) as reldepth,
		coalesce(p.partordinal, 0) as relordinal,
		coalesce(p.partstatus, 't') as relstatus
	from 
		(
			select 
				c.oid, 
				c.relname,
				s.spcname, 
				c.reloptions, 
				c.relhasoids, 
				c.relstorage,
				c.relfilenode
			from 
				pg_class c 
					left join 
				pg_tablespace s 
					on (s.oid = 
						case
							when c.reltablespace != 0 then c.reltablespace
							else (
								select dattablespace 
								from pg_database 
								where datname = current_database() )
						 end
						)
			where relkind = 'r'
		) as r(relid, relname, spcname, reloptions, relhasoids, relstorage, relfilenode) 
		left join 
		(
			select 
				tableid,  
				tabledepth,
				tableid::regclass partid, 
				0 as partdepth, 
				0 as partordinal,
				'r'::char as partstatus
			from 
				(
					select 
						parrelid::regclass,
						max(parlevel)+1
					from
						pg_partition
					group by parrelid
				) as ptable(tableid, tabledepth) 
			union all
			select 
				parrelid::regclass as tableid,  
				t.tabledepth as tabledepth,
				r.parchildrelid::regclass partid, 
				p.parlevel + 1 as partdepth, 
				r.parruleord as partordinal,
				case
					when t.tabledepth = p.parlevel + 1 then 'l'::char
					else 'i'::char
				end as partstatus
			from 
				pg_partition p, 
				pg_partition_rule r,
				 (
					select 
						parrelid::regclass,
						max(parlevel)+1
					from
						pg_partition
					group by parrelid
				) as t(tableid, tabledepth) 
			where 
				p.oid = r.paroid
				and not p.paristemplate
				and p.parrelid = t.tableid
		) as p(tableid, tabledepth, partid, partdepth, partordinal, partstatus) 
		on (r.relid = p.partid);

-- First, partition query, we don't care the constrain name.
select
  n.nspname,
  c.contype,
  c.condeferrable,
  c.condeferred,
  c.conrelid::regclass,
  c.contypid::regtype,
  c.confrelid::regclass,
  c.confupdtype,
  c.confdeltype,
  c.confdeltype,
  c.confmatchtype,
  c.conkey,
  c.confkey,
  c.conbin,
  c.consrc,
  r.relstatus,
  r.relordinal
from pg_constraint c, pg_namespace n, rel_closure r
where c.connamespace = n.oid
  and c.conrelid = r.relid
  and r.relstatus != 't'
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17;

-- second, non partitioned query ignore connname that looks like
-- %_prt_<num>_check
select
  n.nspname,
  c.conname,
  c.contype,
  c.condeferrable,
  c.condeferred,
  c.conrelid::regclass,
  c.contypid::regtype,
  c.confrelid::regclass,
  c.confupdtype,
  c.confdeltype,
  c.confdeltype,
  c.confmatchtype,
  c.conkey,
  c.confkey,
  c.conbin,
  c.consrc,
  r.relstatus,
  r.relordinal
from pg_constraint c, pg_namespace n, rel_closure r
where c.connamespace = n.oid
  and c.conrelid = r.relid
  and r.relstatus = 't'
  --and c.conname not similar to '%_[0-9]+_prt_[0-9]+_check'
  and c.conname not similar to '%_[0-9]+_prt_%_+check'
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18;

-- Also include those relid that doesn't match rel_closure
select
  n.nspname,
  c.conname,
  c.contype,
  c.condeferrable,
  c.condeferred,
  c.conrelid::regclass,
  c.contypid::regtype,
  c.confrelid::regclass,
  c.confupdtype,
  c.confdeltype,
  c.confdeltype,
  c.confmatchtype,
  c.conkey,
  c.confkey,
  c.conbin,
  c.consrc
from pg_constraint c
join pg_namespace n on (c.connamespace = n.oid)
where c.conrelid = 0
order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16;

drop view rel_closure;

