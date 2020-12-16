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
('class: 1-3 or 5-7'),
('row: 6-11 or 33-44'),
('seat: 13-40 or 45-50'),
(''),
('your ticket:'),
('7,1,14'),
(''),
('nearby tickets:'),
('7,3,47'),
('40,4,50'),
('55,2,20'),
('38,6,12')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day16.txt'

drop table if exists #rules

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select	r.rown cid, cast(null as varchar(32)) as class,
		max(case when x.id = 2 and z.id = 1 then cast(z.item as int) else null end) l,
		max(case when x.id = 2 and z.id = 2 then cast(z.item as int) else null end) h
into #rules
from cte_raw r
outer apply (select id, trim(item) item from dbo.fn_split(r.s,':')) as x 
outer apply (select id, trim(item) item from dbo.fn_split(x.item,' ')) as y 
outer apply (select id, trim(item) item from dbo.fn_split(y.item,'-')) as z 
where rown < (select min(rown) from cte_raw where len(s) = 0)
and x.id = 2
and y.id <> 2
group by r.rown, y.id

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
update ru
set class = x.class
from #rules ru
join
(
	select	r.rown cid, 
			max(case when x.id = 1 then x.item else null end)  class
	from cte_raw r
	outer apply (select id, trim(item) item from dbo.fn_split(r.s,':')) as x 
	where rown < (select min(rown) from cte_raw where len(s) = 0)
	group by r.rown
) as x
	on x.cid = ru.cid

drop table if exists #tickets
;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select r.rown tid, case when sid = 1 then 1 else 0 end as MyTicket, 1 IsGood, y.id fieldid, cast(item as int) n 
into #tickets
from cte_raw r
outer apply (select count(*) sid from cte_raw where len(s) = 0 and rown < r.rown) as x
outer apply (select * from dbo.fn_split(r.s,',')) as y 
where len(s) > 0
and x.sid in (1,2)
and CHARINDEX('ticket',s) = 0

select sum(n) part1 
from #tickets t
left join #rules r
	on t.n between r.l and r.h
where MyTicket = 0
and r.l is null

update t
set IsGood = 0
from #tickets t
join (
	select t.tid
	from #tickets t
	left join #rules r
		on t.n between r.l and r.h
	where MyTicket = 0
	and r.l is null
	) as x
	on x.tid = t.tid 

drop table if exists #classes
select class, fieldid
into #classes
from (
	select class, f.fieldid, count(*) t
	from #rules r
	cross join (select distinct fieldid from #tickets) f
	join #tickets t
		on t.fieldid = f.fieldid
		and t.n between r.l and r.h
		and t.IsGood = 1
	group by r.class, f.fieldid
	) x
join (select count(distinct tid) t from #tickets where IsGood = 1) y
	on x.t = y.t
order by class, fieldid

while 1=1
begin
	delete todel
	from (select class from #classes group by class having count(*) = 1) as used
	join #classes c
		on c.class = used.class
	join #classes todel
		on todel.fieldid = c.fieldid
		and todel.class <> c.class

	if @@ROWCOUNT = 0 break
end

declare @score bigint = 1

select @score = @score * n
from #classes c
join #tickets t
	on t.MyTicket = 1
	and t.fieldid = c.fieldid
where c.class like 'departure%'

select @score part2

