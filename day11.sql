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
(    'L.LL.LL.LL'),
(    'LLLLLLL.LL'),
(    'L.L.L..L..'),
(    'LLLL.LL.LL'),
(    'L.LL.LL.LL'),
(    'L.LLLLL.LL'),
(    '..L.L.....'),
(    'LLLLLLLLLL'),
(    'L.LLLLLL.L'),
(    'L.LLLLL.LL')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day11.txt'

drop table if exists #seats

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown r, x.id c
into #seats
from cte_raw r
outer apply (select * from dbo.fn_split(r.s,null)) as x
where x.Item = 'L'

drop table if exists #history
select r,c,0 IsOccupied, 0 iteration
into #history
from #seats

create index I_h on #history(iteration,r,c)

declare @part1 int = 0

declare @maxr int
declare @maxc int
select @maxr = max(r), @maxc = max(c) from #seats

drop table if exists #neigbours
create table #neigbours(r int, c int, near_r int, near_c int)

if @part1 = 1
begin
	-- part 1
	insert into #neigbours
	select s.r,s.c,s1.r, s1.c
	from #seats s
	cross join (select -1 d union select 0 union select 1) r
	cross join (select -1 d union select 0 union select 1) c
	left join #seats s1
		on s1.r = s.r + r.d
		and s1.c = s.c + c.d
	where not (r.d = 0 and c.d = 0 )
	and s1.r is not null
end
else
begin
	-- part 2
	;with cte0(n) as 
		(select 0 union select 1 union select 2 union select 3 union select 4	
		union select 5 union select 6 union select 7 union select 8 union select 9),
		cte100(n) as (select 10*a.n + b.n from cte0 a, cte0 b)
	insert into #neigbours
	select s.r,s.c,near.r,near.c 
	from #seats s
	cross join (select -1 d union select 0 union select 1) r
	cross join (select -1 d union select 0 union select 1) c
	outer apply (
		select top 1 n.n, r, c
		from cte100 n
		left join #seats s1
			on s1.r = s.r + n.n * r.d
			and s1.c = s.c + n.n *c.d
		where s1.r is not null
		and s.r + n.n * r.d between 0 and @maxr
		and s.c + n.n * c.d between 0 and @maxc
		and n.n > 0
		order by n
		) as near
	where not (r.d = 0 and c.d = 0 )
	and near.r is not null
end

create index I_n on #neigbours(r,c)

declare @occupied int = -1
declare @i int = 0
declare @prev_occupied int = 0
while @occupied <> @prev_occupied
begin
	set @prev_occupied = @occupied

	insert into #history
	select 
		s.r, s.c,
		case	when s.IsOccupied = 0 and n = 0 then 1
				when s.IsOccupied = 1 and n >= case @part1 when 1 then 4 else 5 end then 0
				else s.IsOccupied end,
		@i+1
	from #history s
	outer apply (
		select sum(IsOccupied) n
		from #neigbours n
		join #history p
		on p.r = n.near_r
			and p.c = n.near_c
			and iteration = @i 
		where n.r = s.r
		and n.c = s.c
		) as x
	where s.iteration = @i 

	-- clean-up the old tables
	delete #history where iteration < @i

	select @occupied = sum(IsOccupied) from #history where iteration = @i+1 
	raiserror('Running step %d, Occupied %d',0,0,@i,@occupied) with nowait
	set @i = @i + 1


end

select iteration, sum(IsOccupied) Occupied from #history group by iteration


