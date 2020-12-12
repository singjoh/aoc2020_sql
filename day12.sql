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
select Item from dbo.fn_split('F10,N3,F7,R90,F11',',')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day12.txt'

drop table if exists #moves

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown id, substring(s,1,1) as op, cast(substring(s,2,100) as int) n
into #moves
from cte_raw r

drop table if exists #part1
select *
into #part1
from #moves m
outer apply (
	select (sum(case when op = 'L' then 4 - (n / 90) when op = 'R' then n / 90 else 0 end)) % 4 as shipdir -- E,S,W,N 
	from #moves 
	where id <= m.id
	) as x
outer apply (
	select case 
			when m.op = 'F' then substring('ESWN',x.shipdir+1,1)
			else m.op 
			end newop
	) as y

select * from #part1

select	abs(sum(case newop when 'N' then n when 'S' then -n else 0 end)) +
		abs(sum(case newop when 'E' then n when 'W' then -n else 0 end)) part1
from #part1


declare @wx int = 10
declare @wy int = 1
declare @x int = 0
declare @y int = 0

declare @owx int, @owy int
declare @row int, @maxrow int
select @row = 0, @maxrow = max(id) from #moves

declare @op varchar(1)
declare @n int
declare @turn int

while @row < @maxrow
begin
	set @row = @row + 1

	select @op = op, @n = n from #moves where id = @row

    if @op in ('L','R')
	begin
		set @owx = @wx
		set @owy = @wy
        set @turn = (@n / 90) % 4
        if @op = 'L'
            set @turn = 4 - @turn
        if @turn = 1 begin set @wy = -@owx set @wx = @owy end
        if @turn = 2 begin set @wy = -@owy set @wx = -@owx end
        if @turn = 3 begin set @wy = @owx set @wx = -@owy end
        continue

    end    

    if @op = 'N'
        set @wy = @wy + @n
    else if @op = 'E'
        set @wx += @n
    else if @op = 'S'
        set @wy -= @n
    else if @op = 'W'
        set @wx -= @n
    else if @op = 'F'
	begin
        set @x += @n * @wx
        set @y += @n * @wy
	end

	raiserror('Ship at (%d,%d), waypoint (%d,%d)',0,0, @x, @y, @wx , @wy)
end

select abs(@x) + abs(@y) part2
