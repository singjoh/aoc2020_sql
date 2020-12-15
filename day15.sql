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
values ('0,3,6')
--*/
-- real data
insert into #raw 
values ('9,12,1,4,17,0,18')

drop table if exists #data
select cast(item as int) n, id p1, id p2
into #data
from #raw
outer apply (select * from dbo.fn_split(s,',')) as x

create unique index I1 on #data(n)

declare @i int, @n int
select @i = max(p1) from #data
select @n = n from #data where p1 = @i

-- while @i < 2020 -- part1
while @i < 30000000 --part2
begin
	set @i += 1
	
	select @n = p2 - p1
	from #data
	where n = @n

	MERGE #data target
	USING (select @n n ) as source ON target.n = source.n
	WHEN MATCHED THEN UPDATE set p2 = @i, p1 = target.p2 
	WHEN NOT MATCHED THEN INSERT (n,p1,p2) VALUES (@n,@i,@i);

	if @i % 100000 = 0
	raiserror('Working on step %d',0,0,@i)

end

select @n
