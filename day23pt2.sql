set nocount on
SET ANSI_WARNINGS OFF
go
/*


*/
use aoc2020
go

declare @init varchar(10)

--test data
/*
set @init = '389125467'
--*/
-- real data
set @init = '789465123'

drop table if exists #cups
create table #cups(id int, nextid int)

create index i1 on #cups(id)

insert into #cups
select item, lead(item) over (order by id)
from dbo.fn_split(@init,null) 

;WITH
	E1(N)        AS ( SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 
                         UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 
                         UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
    E2(N)        AS (SELECT 1 FROM E1 a, E1 b),
    E4(N)        AS (SELECT 1 FROM E2 a, E2 b),
    E42(N)       AS (SELECT 1 FROM E4 a, E2 b),
    cteTally(N)  AS (SELECT 0 UNION ALL SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E42)
insert into #cups
select n, n+1
from cteTally
where n between 10 and 1000000

-- chain cups onto the remainder
update c
set nextid = 10
from #cups c
where id = cast(substring(@init,9,1) as int)

-- close the circle
update c
set nextid = cast(substring(@init,1,1) as int)
from #cups c
where id = 1000000


declare @id int, @nextid int, @destid int, @cups int, @c1id int, @c3id int, @destnextid int, @move int
set @id = cast(substring(@init,1,1) as int)
set @cups = 1000000
set @move = 0
declare @part1 varchar(10) = ''

while @move < 10000000
begin
	if @move % 10000 = 0
	raiserror('Working on move %i',0,0,@move)

	set @move = @move + 1

	select @nextid = c3.nextid , 
		@destid = y.destid ,
		@c1id = c1.id ,
		@c3id = c3.id ,
		@destnextid = cd.nextid 
	from #cups c0
	join #cups c1
		on c1.id = c0.nextid
	join #cups c2
		on c2.id = c1.nextid
	join #cups c3
		on c3.id = c2.nextid
	outer apply (
		select	case when c0.id - 1 = 0 then @cups when c0.id - 1 < 0 then @cups + c0.id - 1 else c0.id - 1 end destid0, 
				case when c0.id - 2 = 0 then @cups when c0.id - 2 < 0 then @cups + c0.id - 2 else c0.id - 2 end destid1, 
				case when c0.id - 3 = 0 then @cups when c0.id - 3 < 0 then @cups + c0.id - 3 else c0.id - 3 end destid2, 
				case when c0.id - 4 = 0 then @cups when c0.id - 4 < 0 then @cups + c0.id - 4 else c0.id - 4 end destid3 ) as x
	outer apply (
		select 
		case 
			 when x.destid0 not in (c1.id, c2.id, c3.id) then x.destid0
			 when x.destid1 not in (c1.id, c2.id, c3.id) then x.destid1
			 when x.destid2 not in (c1.id, c2.id, c3.id) then x.destid2
			 else x.destid3
		end destid
		) as y
	join #cups cd
		on cd.id = destid
	where c0.id = @id

	update #cups
	set nextid = 
		case id 
		when @id then @nextid
		when @destid then @c1id
		when @c3id then @destnextid
		end
	where id in (@id, @c3id, @destid)

	set @id = @nextid

end

select top 10 * from #cups


select c0.nextid, c1.nextid, cast(c0.nextid as bigint) * c1.nextid part2
from #cups c0
join #cups c1
	on c1.id = c0.nextid
join #cups c2
	on c2.id = c1.nextid
where c0.id = 1