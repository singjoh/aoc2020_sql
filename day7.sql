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
(    'light red bags contain 1 bright white bag, 2 muted yellow bags.'),
(    'dark orange bags contain 3 bright white bags, 4 muted yellow bags.'),
(    'bright white bags contain 1 shiny gold bag.'),
(    'muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.'),
(    'shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.'),
(    'dark olive bags contain 3 faded blue bags, 4 dotted black bags.'),
(    'vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.'),
(    'faded blue bags contain no other bags.'),
(    'dotted black bags contain no other bags.')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day7.txt'

drop table if exists #data

select p, v.n, case v.n when 0 then null else v.c end c
into #data
from #raw r
outer apply (select charindex(' bags contain ',r.s) c) as x
outer apply (select substring(r.s,1,c-1) as p, substring(r.s,c+14,8000) as c) as y
outer apply (select trim(item) c from dbo.fn_split(y.c,',')) as z
outer apply (select charindex(' ',z.c) c, charindex(' bag',z.c) b) as w
outer apply (select case when ISNUMERIC(substring(z.c,1,w.c-1)) = 1 then cast(substring(z.c,1,w.c-1) as int) else 0 end n, substring(z.c,w.c+1, w.b-w.c-1) as c) as v

;with cte as ( 
	select p, c from #data where c = 'shiny gold'
	union all 
	select d.p, c.c from cte c join #data d on d.c = c.p
	)
select count(distinct(p)) part1_recursive  
from cte

;with cte as (
	select p, n, c from #data where p = 'shiny gold' 
	union all 
	select c.p, c.n * d.n, d.c from cte c join #data d on d.p = c.c
	)
select sum(n) part2_recursive 
from cte
