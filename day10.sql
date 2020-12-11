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
select item from dbo.fn_split('16,10,15,5,1,11,7,19,6,12,4',',')


-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day10.txt'

drop table if exists #numbers

select cast(s as int) n, cast(0 as bigint) as paths 
into #numbers
from #raw r

-- start / end
insert into #numbers values (0,1) 
insert into #numbers select max(n) +3, 0 from #numbers 

-- part 1
select sum(case when n - p = 1 then 1 else 0 end) * sum(case when n - p = 3 then 1 else 0 end) part1
from (
	select n, lag(n) over (order by n) p
	from #numbers
) as x
where n > 0

-- part 2
declare @n int = 0

while 1=1
begin
	select @n = min(n) from #numbers where n > @n

	if @n is null break

	update n
	set paths = x.paths
	from #numbers n
	outer apply (select sum(paths) paths from #numbers where n between @n-3 and @n-1) x
	where n.n = @n

end

select max(paths) part2 from #numbers




