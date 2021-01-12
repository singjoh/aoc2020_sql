set nocount on
SET ANSI_WARNINGS OFF
go
/*


*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(8000))

--test data
--/*
insert into #raw 
values 
('sesenwnenenewseeswwswswwnenewsewsw'),
('neeenesenwnwwswnenewnwwsewnenwseswesw'),
('seswneswswsenwwnwse'),
('nwnwneseeswswnenewneswwnewseswneseene'),
('swweswneswnenwsewnwneneseenw'),
('eesenwseswswnenwswnwnwsewwnwsene'),
('sewnenenenesenwsewnenwwwse'),
('wenwwweseeeweswwwnwwe'),
('wsweesenenewnwwnwsenewsenwwsesesenwne'),
('neeswseenwwswnwswswnw'),
('nenwswwsewswnenenewsenwsenwnesesenew'),
('enewnwewneswsewnwswenweswnenwsenwsw'),
('sweneswneswneneenwnewenewwneswswnese'),
('swwesenesewenwneswnwwneseswwne'),
('enesenwswwswneneswsenwnewswseenwsese'),
('wnwnesenesenenwwnenwsewesewsesesew'),
('nenewswnwewswnenesenwnesewesw'),
('eneswnwswnwsenenwnwnwwseeswneewsenese'),
('neswnwewnwnwseenwseesewsenwsweewe'),
('wseweeenwnesenwwwswnew')
--*/
-- real data
-- bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day24.txt'

drop table if exists #rules

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown, row_number() over (partition by rown order by id) id, dir, 
	case	when dir in ('se','e') then 1
			when dir in ('nw','w') then -1
			else 0
	end x,
	case	when dir in ('ne','e') then 1
			when dir in ('sw','w') then -1
			else 0
	end y
into #rules
from (
	select rown, id, case when prefix in ('n','s') then prefix else '' end + item dir
	from (
		select rown, id, item, lag(item) over (partition by r.rown order by id) prefix
		from cte_raw r
		outer apply (select * from dbo.fn_split(s,null)) as z ) as x
	where item in ('e','w')
	) as y

drop table if exists #pattern
select 0 dayn, x, y -- all tiles that have flipped
into #pattern
from (
	select rown, sum(x) x, sum(y) y -- add up movements to find which tile is moved
	from #rules
	group by rown
) as x
group by x, y
having count(*) % 2 = 1 -- only include tiles wher there are an odd number of flips

select count(*) part1 -- sum the tiles
from #pattern 

create index i_pattern on #pattern(dayn,x,y)

drop table if exists #neighbours
create table #neighbours(dx int, dy int)
insert into #neighbours
values (0,0), (1,0), (0,1), (1,1), (-1,0), (0,-1), (-1,-1)


declare @day int = 0

--Any black tile with zero or more than 2 black tiles immediately adjacent to it is flipped to white.
--Any white tile with exactly 2 black tiles immediately adjacent to it is flipped to black.
while @day < 100
begin

	insert into #pattern
	select @day+1, x, y
	from (
		select t.x, t.y, c, case when p.x is not null then 1 else 0 end IsBlack
		from (
			select x,y,count(*) c
			from (
				select p.x+dx x, p.y+dy y
				from #pattern p 
				cross join #neighbours 
				where dayn = @day
			) as x
			group by x, y
		) as t
		left join #pattern p 
			on p.x = t.x
			and p.y = t.y
			and p.dayn = @day
	) as x
	where 1 = 
		case	when IsBlack = 0 then
					case when c = 2 then 1 
						 else 0 
					end
				when IsBlack = 1 then	
					case when c = 1 then 0 -- if Black then at least one 'neighbour', itself
	      				 when c > 3 then 0
						 else 1
					end
		end
	order by isblack, x, y

	set @day = @day + 1

end

select count(*) part2 -- sum the tiles
from #pattern 
where dayn = 100

