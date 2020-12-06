set nocount on
go
/*


*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(100))

--test data
/*
insert into #raw 
values
('abc'),
(''),
('a'),
('b'),
('c'),
(''),
('ab'),
('ac'),
(''),
('a'),
('a'),
('a'),
('a'),
(''),
('b')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day6.txt'

drop table if exists #data

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select  grpid, grpsize, question, count(*) c
into #data
from (
	select rown, x.id grpid, item question, 1 + max(rown) over (partition by x.id) - min(rown) over (partition by x.id) grpsize 
	from cte_raw r
	outer apply (select 1+count(*) id from cte_raw where rown < r.rown and len(s) = 0) as x
	outer apply (select * from dbo.fn_split(s,null)) as y 
	where len(s) > 0 
) as x
group by grpid, grpsize, question

-- part 1 (just count the rows, each is an answer to any question)
select count(c) part1 from #data

-- part 2 (coun the items where grpsize = answer size)
select count(c) part2 from #data
where grpsize = c

