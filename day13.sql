use aoc2020
go

set nocount on
go
/*

create function mul_inv(@a bigint, @b bigint)
returns bigint
as
begin
	declare @b0 bigint = @b
	declare @x0 bigint = 0, @x1 bigint = 1
	declare @q bigint
	declare @temp bigint
    if @b = 1 return 1
    while @a > 1
	begin
        set @q = @a / @b
		set @temp = @b
		set @b = @a % @b 
		set @a = @temp
		set @temp = @x0
		set @x0 =  @x1 - @q * @x0
		set @x1 = @temp
	end
    if @x1 < 0 set @x1 += @b0
    return @x1
end

*/

drop table if exists #raw
create table #raw (s varchar(8000))

declare @ts bigint


--test data
/*
set @ts = 939

insert into #raw 
select Item from dbo.fn_split('7,13,x,x,59,x,31,19',',')

-- */

-- real data
set @ts = 1000417

insert into #raw 
select Item from dbo.fn_split('23,x,x,x,x,x,x,x,x,x,x,x,x,41,x,x,x,37,x,x,x,x,x,479,x,x,x,x,x,x,x,x,x,x,x,x,13,x,x,x,17,x,x,x,x,x,x,x,x,x,x,x,29,x,373,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,19',',')

drop table if exists #buses

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown - 1 id, case when s = 'x' then null else cast(s as int) end busid
into #buses
from cte_raw r

declare @offset bigint
declare @bus int
set @offset = 0
while 1=1
begin
	
	select @bus = busid
	from #buses
	where busid is not null
	and (@ts + @offset) % busid = 0

	if @bus is not null break

	set @offset += 1
end

select @bus busid, @offset * @bus part1

-- Chinese Remainder theorum
drop table if exists #crt
select ROW_NUMBER() over (order by id) rowid, busid divider, busid - id remainder, cast (null as bigint) as working
into #crt
from #buses
where busid is not null

-- get the product of the dividers
declare @prod bigint = 1
declare @rowid int, @maxrowid int
select @rowid = 0, @maxrowid = max(rowid) from #crt
while @rowid < @maxrowid
begin
	set @rowid += 1
	select @prod = @prod * divider from #crt where rowid = @rowid
end

-- now build the working values for the sum
update c
set working = remainder * p * dbo.mul_inv(p,divider)
from #crt c
outer apply (select @prod / divider p ) as x

select sum(working) % @prod part2 from #crt