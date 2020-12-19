set nocount on
go
/*


*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(8000))

--test data
/*
insert into #raw 
values 
('0: 1 2'),
('1: "a"'),
('2: 1 3 | 3 1'),
('3: "b"'),
(''),
('aba')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day19.txt'

drop table if exists #rules


;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw),
	cte_break(rown) as (select min(rown) from cte_raw where len(s) = 0),
	cte_rules(s) as (select s from cte_break b join cte_raw r on r.rown < b.rown)
select	substring(s,1,colonloc-1) id, 
		y.id optid,
		case when left(y.item,1) <> '"' then y.item else null end rules,
		cast(case when left(y.item,1) = '"' then substring(y.item,2,1) else null end as varchar(8000)) as msg,
		max(case when left(y.item,1) <> '"' and z.id = 1 then z.item else null end) cid1, 
		max(case when left(y.item,1) <> '"' and z.id = 2 then z.item else null end) cid2
into #rules
from cte_rules r
outer apply (select CHARINDEX(':',s) colonloc) as x
outer apply (select id, TRIM(item) item from dbo.fn_split(substring(s,colonloc+2,8000),'|')) as y
outer apply (select * from dbo.fn_split(y.item,' ')) as z
group by s, y.item, y.id, colonloc
order by 1,2,3,4

drop table if exists #messages

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw),
	cte_break(rown) as (select min(rown) from cte_raw where len(s) = 0),
	cte_messages(s) as (select s from cte_break b join cte_raw r on r.rown > b.rown)
select s msg into #messages from cte_messages

drop table if exists #expanded
select id, optid, cast(msg as varchar(8000)) msg
into #expanded
from #rules
where msg is not null

create index i1 on #expanded(id, optid)

drop table if exists #ready
select id
into #ready
from #expanded

-- expand the rules 
while 1=1
begin
	insert into #expanded (id, optid, msg)
	select distinct p.id, p.optid, e1.msg + isnull(e2.msg,'')
	from #rules p
	join #rules c1
		on c1.id = p.cid1
	join #ready r1
		on r1.id = c1.id
	join #expanded e1
		on e1.id = c1.id
		and e1.optid = c1.optid
	left join (
		select c.id, c.optid, e.msg
		from #rules c
		join #ready r
			on r.id = c.id
		join #expanded e
			on e.id = c.id
			and e.optid = c.optid
			) as e2
		on e2.id = p.cid2
	where (p.cid2 is null or e2.id is not null)
	and not exists ( select top 1 1 from #expanded where id = p.id and optid = p.optid )

	if @@ROWCOUNT = 0 break

	insert into #ready
	select e.id
	from (
		select id, count(distinct optid) c
		from #expanded
		group by id
	) as e
	join (
		select id, count(distinct optid) c
		from #rules
		group by id
	) as r
		on r.id =e.id
	left join #ready o
		on o.id = e.id
	where e.c = r.c
	and o.id is null

end

select count(*) part1 
from #expanded r
join #messages m
	on m.msg = r.msg
where id = 0 and r.msg is not null

-- reiew data for part2
select min(len(msg)), max(len(msg)) from #messages 
select id, min(len(msg)), max(len(msg)), count(*) from #expanded where id in (8,11,31,42) group by id
-- 8: 42 | 42 8
-- 11: 42 31 | 42 11 31
-- 0: 42+ 31+ (or more descriptively 42{2} 42(m) 42(n) 31(n) 31)

-- clear out the current 0,8,11 rules to make the parsing quicker
delete from #expanded where id in (0,8,11)

drop table if exists #matches

;with cte_n(n) as (
	select 1 union select 2 union select 3 union select 4 union select 5 union select 6
	union select 7 union select 8 union select 9 union select 10 union select 0)
select m.msg, n, mxn, id
into #matches
from #messages m
cross join cte_n
outer apply (select SUBSTRING(msg,1+n*8,8) as chunk) as x
outer apply (select len(m.msg) / 8 as mxn) as y
join #expanded chunk1
	on chunk1.msg = x.chunk
	and chunk1.id in (42,31) -- to help the optimiser
	and chunk1.id =
		case	when n in (0,1) then 42
				when n = mxn -1 then 31
				else chunk1.id end
where mxn > n
order by m.msg,n, chunk

-- quick check, does part1 still produce the same number
select count(*) part1
from (
	select msg, mxn, count(*) c from #matches
	group by msg, mxn
) as x
where mxn=3 and c = 3

-- 0: 42 42 n*42 m*42 m*31 31 
-- last 42 = 2 + n + m
-- first 31 = 2 + n + m + 1 = mv - 1 - m (-1 due to 0 index of n)

select count(*) part2
from (select msg, mxn, count(*) c from #matches group by msg, mxn) m
outer apply (select max(n) last42 from #matches where id = 42 and msg = m.msg) as x
outer apply (select min(n) first31 from #matches where id = 31 and msg = m.msg) as y
where mxn=c 
and last42 = first31 - 1 -- all 42 records must preceed 31
and mxn - first31 - 1 < last42 -- check we haven't got too many 31

