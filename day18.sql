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
('2 + 3 + 4'),
('2 * 3 + (4 * 5)'),
('((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day18.txt'

drop table if exists #data

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(replace(s,' ',''),'')
	from #raw)
select rown, s, id, item, sum(case item when '(' then 1 when ')' then -1 else 0 end) over (partition by s order by id) depth
into #data
from cte_raw r
outer apply (select * from dbo.fn_split(r.s,null)) as x

-- this calc only, so not joining on big tables in our while loop
drop table if exists #thisdata
select rown, id, item, depth into #thisdata from #data where 1=2

-- location of 'plus' in the calc, for part2
drop table if exists #plus
create table #plus (rown int, id int)

declare @rown int, @maxrown int
declare @plusrown int, @maxplusrown int
declare @sectionstart int, @sectionend int
declare @step int
declare @result bigint
declare @depth int

declare @part int = 2

select @rown = 0, @maxrown = max(rown) from #data


while @rown < @maxrown
begin
	set @rown += 1

	-- copy data from big #data to a smaller handling table
	truncate table #thisdata
	insert into #thisdata
	select rown, id, item, depth from #data
	where rown = @rown

	-- main loop, repeat until we've performed the outer calc (depth=0)
	while 1=1
	begin

		-- find the first inner section with the lowest depth
		select @sectionstart = bopen.id, @sectionend = isnull(bclose.id,bend.id), @result = cast(item as bigint), @depth = mx.depth
		from #thisdata d
		outer apply (select max(depth) depth from #thisdata) mx
		-- ignore brackets
		outer apply (select min(id) id from #thisdata d where depth = mx.depth and item <> '(' ) as bopen
		outer apply (select min(id) id from #thisdata d where item = ')' and id > bopen.id) as bclose
		outer apply (select max(id) id from #thisdata d) as bend
		where d.id = bopen.id

		if @part = 1
		begin
			-- part 1, loop over the ops in turn, applying op and rhs to the current lhs (found when finding the inner section)
			set @step = @sectionstart + 1
	
			while 1=1
			begin
				select @result =
						case when op = '+' 
							then @result + rhs
							else @result * rhs
						end, 
						@step = @step + 2 -- step by 2 (op and rhs term)
				from (
					select id, item op, lead(item,1) over (partition by rown order by id) as rhs
					from #thisdata d
					where id between @step and @step+1
				) as x
				where id = @step
				and op in ('+','*')

				if @step >= @sectionend break -- we've finished with the section
			end
		end
		else
		begin
			-- part 2, start by identifying the '+' in this section
			truncate table #plus
			insert into #plus
			select ROW_NUMBER() over (order by id), id
			from #thisdata
			where id between @sectionstart and @sectionend
			and item = '+'

			-- for each plus in turn,
			-- replace rhs rows with lhs+rhs, and delete the lhs and op rows

			select @plusrown = 0, @maxplusrown = max(rown) from #plus
			while @plusrown < @maxplusrown
			begin
				set @plusrown += 1
				update t
				set item = cast(cast(lhs as bigint)+cast(rhs as bigint) as varchar(32))
				from #thisdata t
				outer apply (
					select p.id+1 endid, lhs, rhs
					from (
						select id, lag(item) over (order by id) lhs, item op, lead(item) over (order by id) rhs
						from #thisdata
						) as x
					join #plus p
						on p.id = x.id
					where p.rown = @plusrown
				) as x
				where t.id = x.endid

				delete t
				from #plus p
				join #thisdata t
					on t.id between p.id-1 and p.id
				where p.rown = @plusrown

			end

			-- the section will now include the presummed sections (and '*' signs, and the trailing bracket)
			-- so we can just make a product of whats left
			set @result = 1
			select @result = @result * cast(item as bigint) from #thisdata 
			where id between @sectionstart and @sectionend
			and item not in (')','*')

		end

		-- @result now holds the value of the section under consideration
		if @depth > 0
		begin
			-- if this was not the outer level, replace the section with the result
			-- and resequence (squash the gaps) [required for part 1 only, because we step to the next op with id = id+2]
			delete #thisdata
			where id between @sectionstart - 1 and @sectionend

			insert into #thisdata (rown, id, item, depth)
			values (@rown, @sectionstart -1, cast(@result as varchar(32)), @depth-1)

			-- resequence
			update d
			set d.id = n.oid
			from #thisdata d
			join (
				select id, ROW_NUMBER() over (order by id) oid
				from #thisdata where rown = @rown) as n
				on n.id = d.id
		end
		else
		begin
			-- outer most calc
			-- here we replace the summary data 
			update d
			set item = cast(@result as varchar(32)),
				depth = 0 -- not used again, but removes confusion
			from #data d
			where rown = @rown 
			and id = 1

			delete #data
			where rown = @rown 
			and id > 1

			break
		end
	end
end

select sum(cast(item as bigint)) from #data 



select * from #data


