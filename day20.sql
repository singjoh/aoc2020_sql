set nocount on
go
/*


*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(8000))

--test data
--/*
--bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day20test.txt'

--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day20.txt'

drop table if exists #tiles

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw),
	cte_tile(rown, tilerank,tileid) as (select rown, row_number() over (order by rown) tilerank, cast(SUBSTRING(s,6,4) as int) from cte_raw where left(s,4) = 'Tile')
select tileid, ROW_NUMBER() over (partition by tilerank order by r.rown ) r, s
into #tiles
from cte_raw r
outer apply (select top 1 tilerank, tileid from cte_tile where rown <= r.rown order by tilerank desc) as t  
where len(s) > 0
and left(s,4) <> 'Tile'

drop table if exists #edges
create table #edges(tileid int, edge varchar(10))

-- top/bottom (l->r) and sides (t->b)
insert into #edges
select * 
from ( 
	select tileid, s
	from #tiles
	where r in (1,10)
	union 
	select tileid, 
		  max(case when r = 1 then substring(s,1,1) else null end)
		+ max(case when r = 2 then substring(s,1,1) else null end)
		+ max(case when r = 3 then substring(s,1,1) else null end)
		+ max(case when r = 4 then substring(s,1,1) else null end)
		+ max(case when r = 5 then substring(s,1,1) else null end)
		+ max(case when r = 6 then substring(s,1,1) else null end)
		+ max(case when r = 7 then substring(s,1,1) else null end)
		+ max(case when r = 8 then substring(s,1,1) else null end)
		+ max(case when r = 9 then substring(s,1,1) else null end)
		+ max(case when r = 10 then substring(s,1,1) else null end)
	from #tiles
	group by tileid
	union 
	select tileid, 
		  max(case when r = 1 then substring(s,10,1) else null end)
		+ max(case when r = 2 then substring(s,10,1) else null end)
		+ max(case when r = 3 then substring(s,10,1) else null end)
		+ max(case when r = 4 then substring(s,10,1) else null end)
		+ max(case when r = 5 then substring(s,10,1) else null end)
		+ max(case when r = 6 then substring(s,10,1) else null end)
		+ max(case when r = 7 then substring(s,10,1) else null end)
		+ max(case when r = 8 then substring(s,10,1) else null end)
		+ max(case when r = 9 then substring(s,10,1) else null end)
		+ max(case when r = 10 then substring(s,10,1) else null end)
	from #tiles
	group by tileid
) as x

insert into #edges
select tileid, REVERSE(edge)
from #edges

-- assuming that all edges can be matched, apart from externals
-- then edge pieces have 2 unmatched (item and reversed)
-- corner pieces have 4 unmatched
/*
select e.tileid 
from #edges e
left join #edges e2
	on e.tileid <> e2.tileid
	and e.edge = e2.edge
where e2.edge is null
group by e.tileid
having count(*) = 4

if @@ROWCOUNT <> 4 
	raiserror('Assertion failed, expect 4 corners',11,11)
	-- */

declare @product bigint = 1
select @product = @product * cast(e.tileid as int)
from #edges e
left join #edges e2
	on e.tileid <> e2.tileid
	and e.edge = e2.edge
where e2.edge is null
group by e.tileid
having count(*) = 4

select @product part1



-- flip/rotate all tiles

drop table if exists #tileperms
select * into #tileperms
from 
(
	select tileid, r, s, 0 flip, 0 rotate
	from #tiles
	union 
	select tileid, r, reverse(s), 1 flip, 0 rotate
	from #tiles
) as x

declare @rotateid int = 0
while @rotateid < 3
begin
	set @rotateid += 1

	insert into #tileperms (tileid, r, s, flip, rotate)

	select tileid, u.r, reverse (
		  max(case when t.r = 1 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 2 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 3 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 4 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 5 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 6 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 7 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 8 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 9 then substring(s,u.r,1) else null end)
		+ max(case when t.r = 10 then substring(s,u.r,1) else null end) ),
		flip, @rotateid
	from #tileperms t
	cross join ( select distinct r from #tiles ) as u
	where rotate = @rotateid - 1
	group by tileid, u.r, flip
end

-- build an edge list for all the different tie orientations (with column for each of top, left, bottom and right sides) 

drop table if exists #edges2
select tileid, rotate, flip, 
	max(case when r = 1 then s else null end) tops,
	cast (null as varchar(10)) as rhs,
	max(case when r = 10 then s else null end) bots,
	cast (null as varchar(10)) as lhs
into #edges2
from #tileperms
where r in (1,10)
group by tileid, rotate, flip

update e2
set lhs = x.lhs,
	rhs = x.rhs
from #edges2 e2
join ( 
	select tileid, rotate, flip, 
		  max(case when r = 1 then substring(s,1,1) else null end)
		+ max(case when r = 2 then substring(s,1,1) else null end)
		+ max(case when r = 3 then substring(s,1,1) else null end)
		+ max(case when r = 4 then substring(s,1,1) else null end)
		+ max(case when r = 5 then substring(s,1,1) else null end)
		+ max(case when r = 6 then substring(s,1,1) else null end)
		+ max(case when r = 7 then substring(s,1,1) else null end)
		+ max(case when r = 8 then substring(s,1,1) else null end)
		+ max(case when r = 9 then substring(s,1,1) else null end)
		+ max(case when r = 10 then substring(s,1,1) else null end) lhs,
		  max(case when r = 1 then substring(s,10,1) else null end)
		+ max(case when r = 2 then substring(s,10,1) else null end)
		+ max(case when r = 3 then substring(s,10,1) else null end)
		+ max(case when r = 4 then substring(s,10,1) else null end)
		+ max(case when r = 5 then substring(s,10,1) else null end)
		+ max(case when r = 6 then substring(s,10,1) else null end)
		+ max(case when r = 7 then substring(s,10,1) else null end)
		+ max(case when r = 8 then substring(s,10,1) else null end)
		+ max(case when r = 9 then substring(s,10,1) else null end)
		+ max(case when r = 10 then substring(s,10,1) else null end) rhs
	from #tileperms
	group by tileid, rotate, flip	
) as x
	on x.tileid = e2.tileid
	and x.rotate = e2.rotate
	and x.flip = e2.flip


declare @tileid00 int
declare @tileid int
declare @rhs varchar(10)

-- find a tile to go in 1,1 position
-- this is one that has 4 unmatched edges (2 numtahced, but since the tile can be flipped thtat makes 4)
-- then join to a tile on the right and left to ensure we have the corret orientation
select top 1 @tileid00 = e.tileid, @rhs = e.rhs
from 
(	select e.tileid from #edges e
	left join #edges e2
		on e.tileid <> e2.tileid
		and e.edge = e2.edge
	where e2.edge is null
	group by e.tileid 
	having count(*) = 4
	) as x
join #edges2 e
	on e.tileid = x.tileid
join #edges2 e2
	on e2.tileid <> e.tileid
	and e2.lhs = e.rhs
join #edges2 e3
	on e3.tileid <> e.tileid
	and e3.tops = e.bots
--where e.tileid = 1951 -- to match test data
--and e.edge = '.#..#####.'
order by e.tileid


-- now position the tiles in a grid, i.e. where (1,1) is top left, then (2,1) lhs = (1,1) rhs, and (1,2) top = (1,1) bottom
drop table if exists #pos
create table #pos(i int identity (1,1), r int, c int, tileid int, rotate int, flip int)

-- select one corner into the grid
insert into #pos (r,c,tileid, rotate, flip)
select top 1 1,1, tileid, rotate, flip
from #edges2 
where tileid = @tileid00
and rhs = @rhs

declare @gridsize int
select @gridsize = sqrt(count(distinct tileid)) from #tiles

declare @r int = 1, @c int = 1

while @r <= @gridsize
begin
	while @c < @gridsize
	begin

		insert into #pos (r,c,tileid, rotate, flip)
		select @r, @c+1, e2.tileid, e2.rotate, e2.flip
		from #pos p
		join #edges2 e
			on e.tileid = p.tileid
			and e.rotate = p.rotate
			and e.flip = p.flip
		join #edges2 e2
			on e2.tileid <> e.tileid
			and e2.lhs = e.rhs
		where p.r = @r
		and p.c = @c

		set @c += 1
	end

	insert into #pos (r,c,tileid, rotate, flip)
	select @r+1, 1, e2.tileid, e2.rotate, e2.flip
	from #pos p
	join #edges2 e
		on e.tileid = p.tileid
		and e.rotate = p.rotate 
		and e.flip = p.flip
	join #edges2 e2
		on e2.tileid <> e.tileid
		and e2.tops = e.bots
	where p.r = @r
	and p.c = 1

	set @r += 1
	set @c = 1

end

-- build the image (take the 2-9 items from image, only where the bit is set
drop table if exists #image
select (p.c-1)*8 + x-1 x, (p.r-1)*8 + t.r-1 y
into #image
from #pos p 
join #tileperms t
			on t.tileid = p.tileid
			and t.rotate = p.rotate
			and t.flip = p.flip
cross join ( select distinct r x from #tiles where r between 2 and 9 ) as x
where t.r between 2 and 9
and SUBSTRING(s,x,1) = '#'
order by 1,2

-- load up the monster template
drop table if exists #raw_monster
create table #raw_monster(rown int, s varchar(100))
insert into #raw_monster
values
(3,'                  # '),
(2,'#    ##    ##    ###'),
(1,' #  #  #  #  #  #   ')

-- and put it in the same x,y bit set style
drop table if exists #monster

select id - 1 x, rown -1 y,  0 flip, 0 rotate 
into #monster
from #raw_monster r
outer apply (select * from dbo.fn_split(r.s, null)) as x

-- build the other monster orientations
-- flipped
insert into #monster
select 19-x,y,1,0
from #monster

-- rotated
set @rotateid = 0
while @rotateid < 3
begin
	set @rotateid += 1

	insert into #monster
	select  my-y x, x y, flip, @rotateid
	from #monster m
	outer apply (select max(y) my from #monster where rotate = m.rotate and flip = m.flip) x
	where rotate=@rotateid - 1
end

-- double check monster orientations
-- for each point in the image, map that to 'first' (any) point in monster, then count up how many other moster points match
-- repeat for each moster orientation
-- we expect to see anumber of monsters, but all in the same flip / rotate
; with cte_p1 as (
	select x, y, flip, rotate
	from (select distinct flip, rotate from #monster) m
	outer apply (select top 1 x,y from #monster where rotate = m.rotate and flip = m.flip) as m1 )
select top 10 * 
from #image i
cross join cte_p1 p1
outer apply (
	select count(*) c
	from #monster m
	join #image i2
		on i2.x = i.x - p1.x + m.x
		and i2.y = i.y - p1.y + m.y
	where m.rotate = p1.rotate and m.flip = p1.flip ) as x
where c = (select count(*) from #monster where flip = 0 and rotate = 0)

declare @mcount int, @msize int

-- now we can simply count the number of monsters (and the number of image points in a monster)
; with cte_p1 as (
	select x, y, flip, rotate
	from (select distinct flip, rotate from #monster) m
	outer apply (select top 1 x,y from #monster where rotate = m.rotate and flip = m.flip) as m1 )
select @msize = x.c, @mcount = count(*)
from #image i
cross join cte_p1 p1
outer apply (
	select count(*) c
	from #monster m
	join #image i2
		on i2.x = i.x - p1.x + m.x
		and i2.y = i.y - p1.y + m.y
	where m.rotate = p1.rotate and m.flip = p1.flip ) as x
where c = (select count(*) from #monster where flip = 0 and rotate = 0)
group by x.c

-- and finally, number of points in image, less those associated with monster, is the answer
select count(*) - @mcount * @msize part2 from #image