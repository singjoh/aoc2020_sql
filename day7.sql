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

drop table if exists #part1
create table #part1 (bag varchar(32))
insert into #part1 values ('shiny gold')

while 1=1
begin
	insert into #part1
	select distinct p 
	from #data d
	join #part1 c
		on c.bag = d.c
	left join #part1 p
		on p.bag = d.p
	where p.bag is null

	if @@ROWCOUNT = 0 break
end

select count(*) - 1 'part1' from #part1

drop table if exists #part2
create table #part2 (nestlvl int, n int, bag varchar(32))
insert into #part2 values (1,1,'shiny gold')

declare @nestlvl int = 0
while 1=1
begin
	set @nestlvl = @nestlvl + 1
	insert into #part2

	select @nestlvl + 1, d.n * p.n, d.c 
	from #part2 p
	join #data d
		on d.p = p.bag
	where nestlvl = @nestlvl
	and d.c is not null

	if @@ROWCOUNT = 0 break
end
select sum(n) - 1 part2 from #part2