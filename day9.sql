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
select item from dbo.fn_split('35,20,15,25,47,40,62,55,65,95,102,117,150,182,127,219,299,277,309,576',',')


-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day9.txt'

drop table if exists #numbers

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown, cast(s as bigint) n 
into #numbers
from cte_raw r

declare @samplesize int = 25
declare @target int

select top 1 @target = t.n
from #numbers t
outer apply (
	select top 1 1 n
	from #numbers i
	join #numbers j
		on j.rown between t.rown - @samplesize and t.rown - 1
		and j.n <> i.n
		and j.n = t.n - i.n
	where i.rown between t.rown - @samplesize and t.rown - 1 ) as x
where t.rown > @samplesize
and x.n is null
order by t.rown

select @target part1

select top 1 mx+mn
from #numbers n1
join #numbers n2
	on n2.rown > n1.rown
outer apply (select sum(n) s, min(n) mn, max(n) mx from #numbers where rown between n1.rown and n2.rown) as s
where s.s = @target
