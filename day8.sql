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
(    'nop +0'),
(    'acc +1'),
(    'jmp +4'),
(    'acc +3'),
(    'jmp -3'),
(    'acc -99'),
(    'acc +1'),
(    'jmp -4'),
(    'acc +6')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day8.txt'

drop table if exists #prog

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown step, max(case when id = 1 then item else null end) op, max(case when id = 2 then cast(item as int) else null end) offset   
into #prog
from cte_raw r
outer apply (select * from dbo.fn_split(r.s,' ')) as x
group by rown


drop table if exists #progrun
select * into #progrun from #prog where 1=0

declare @step int = 1
declare @op varchar(3), @offset int, @progsize int

select @progsize = max(step) from #prog

while 1=1
begin
	if exists (select 1 from #progrun where step = @step)	
		break
	
	select @op = op, @offset = offset
	from #prog
	where step = @step

	insert into #progrun values(@step, @op, @offset)

	if @op in ('nop','acc')
		set @step = @step + 1
	else -- jmp
		set @step = @step + @offset

	if @step > @progsize
		break

end

select sum(offset) part1 from #progrun where op = 'acc'

declare @steptochange int
select @steptochange = max(step) from #prog where op in ('nop','jmp')

while 1=1
begin
	if @steptochange = -1
		break

	truncate table #progrun
	set @step = 1

	while 1=1
	begin
		-- found a loop, go to the next loop test
		if exists (select 1 from #progrun where step = @step)	
		begin
			select @steptochange = max(step) from #prog where op in ('nop','jmp') and step < @steptochange
			break
		end

		select @op = op, @offset = offset
		from #prog
		where step = @step

		if @step = @steptochange
		begin
			if @op = 'jmp' set @op = 'nop'
			else set @op = 'jmp'
		end

		insert into #progrun values(@step, @op, @offset)

		if @op in ('nop','acc')
			set @step = @step + 1
		else -- jmp
			set @step = @step + @offset

		-- a good run
		if @step > @progsize
		begin
			select @steptochange = -1
			break
		end
	end
end

select sum(offset) part2 from #progrun where op = 'acc'
