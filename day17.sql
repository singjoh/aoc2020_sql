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
('.#.'),
('..#'),
('###')
--*/
-- real data
insert into #raw 
values 
('...#..#.'),
('.....##.'),
('##..##.#'),
('#.#.##..'),
('#..#.###'),
('...##.#.'),
('#..##..#'),
('.#.#..#.')
--*/

drop table if exists #grid3d

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select 0 cycle, rown x, x.id y, 0 z
into #grid3d
from cte_raw r
outer apply (select * from dbo.fn_split(r.s,null)) as x
where x.Item = '#'

declare @cycle int = 0

while @cycle < 6
begin

	;with cte(n) as (select -1 union select 0 union select 1) 
	insert into #grid3d
	select @cycle+1, n.* 
	from ( 	
		select distinct nx x, ny y, nz z
		from #grid3d this
		outer apply (select this.x + n nx from cte) nx
		outer apply (select this.y + n ny from cte) ny
		outer apply (select this.z + n nz from cte) nz
		where cycle = @cycle
		) as n
	outer apply (
		select count(*) c from #grid3d
		where cycle = @cycle
		and x between n.x-1 and n.x+1
		and y between n.y-1 and n.y+1
		and z between n.z-1 and n.z+1
		and not (x=n.x and y=n.y and z=n.z)
		) as c
	left join #grid3d old
		on old.cycle = @cycle
		and old.x = n.x
		and old.y = n.y
		and old.z = n.z
	where c = 3
	or (c = 2 and old.x is not null)

	set @cycle += 1
end

select cycle, count(*) from #grid3d
group by cycle
order by cycle

drop table if exists #grid4d

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select 0 cycle, rown x, x.id y, 0 z, 0 w
into #grid4d
from cte_raw r
outer apply (select * from dbo.fn_split(r.s,null)) as x
where x.Item = '#'

set @cycle = 0

while @cycle < 6
begin

	;with cte(n) as (select -1 union select 0 union select 1) 
	insert into #grid4d
	select @cycle+1, n.* 
	from ( 	
		select distinct nx x, ny y, nz z, nw w
		from #grid4d this
		outer apply (select this.x + n nx from cte) nx
		outer apply (select this.y + n ny from cte) ny
		outer apply (select this.z + n nz from cte) nz
		outer apply (select this.w + n nw from cte) nw
		where cycle = @cycle
		) as n
	outer apply (
		select count(*) c from #grid4d
		where cycle = @cycle
		and x between n.x-1 and n.x+1
		and y between n.y-1 and n.y+1
		and z between n.z-1 and n.z+1
		and w between n.w-1 and n.w+1
		and not (x=n.x and y=n.y and z=n.z and w=n.w)
		) as c
	left join #grid4d old
		on old.cycle = @cycle
		and old.x = n.x
		and old.y = n.y
		and old.z = n.z
		and old.w = n.w
	where c = 3
	or (c = 2 and old.x is not null)

	set @cycle += 1
end

select cycle, count(*) from #grid4d
group by cycle
order by cycle