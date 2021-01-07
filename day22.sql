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
/*
insert into #raw 
values 
('Player 1:'),
('9'),
('2'),
('6'),
('3'),
('1'),
(''),
('Player 2:'),
('5'),
('8'),
('4'),
('7'),
('10')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day22.txt'

drop table if exists #p
create table #p(id bigint identity(1,1), player int, card int)


;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
insert into #p(player,card)
select player, cast(s as int) card
from cte_raw r
outer apply (select count(*) + 1 player from cte_raw where rown < r.rown and len(s) = 0) as x
where ISNUMERIC(s) = 1

declare @p1id bigint, @p2id bigint, @p1 int, @p2 int
while 1=1
begin

	select 
		@p1id = max(case when p.player = 1 then p.id else null end) , 
		@p2id = max(case when p.player = 2 then p.id else null end) , 
		@p1 = max(case when p.player = 1 then card else null end) , 
		@p2 = max(case when p.player = 2 then card else null end)  
	from (select player, min(id) id from #p group by player) pmn
	join #p p
		on p.id = pmn.id

	if @p1id is null or @p2id is null
	break

	if @p1 > @p2
		insert into #p (player,card)
		values (1,@p1),(1,@p2)
	else
		insert into #p (player,card)
		values (2,@p2),(2,@p1)

	delete #p where id in (@p1id,@p2id)
end 

declare @score int = 0

select @score = @score + card * ROW_NUMBER() over (order by id desc) from #p 

select @score part1

-- reset the cards

drop table if exists #p2
create table #p2(id bigint identity(1,1), player int, card int, depth int)

drop table if exists #seen
create table #seen(player int, state varchar(max), depth int)

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
insert into #p2(player,card,depth)
select player, cast(s as int) card, 0
from cte_raw r
outer apply (select count(*) + 1 player from cte_raw where rown < r.rown and len(s) = 0) as x
where ISNUMERIC(s) = 1

declare @depth int = 0
declare @p1c int, @p2c int, @winner int

declare @p1s varchar(max), @p2s varchar(max) 

declare @round int = 0
while 1=1
begin
	set @round = @round + 1

	select 
		@p1id = max(case when p.player = 1 then p.id else null end), 
		@p2id = max(case when p.player = 2 then p.id else null end), 
		@p1 = max(case when p.player = 1 then card else null end), 
		@p2 = max(case when p.player = 2 then card else null end),  
		@p1c = max(case when p.player = 1 then c else null end), 
		@p2c = max(case when p.player = 2 then c else null end)  
	from (select player, min(id) id, count(*) c from #p2 where depth = @depth group by player) pmn
	join #p2 p
		on p.id = pmn.id

	set @p1s = ''
	set @p2s = ''
	select	@p1s = @p1s + case when player = 1 then cast(card as varchar) + ',' else '' end, 
			@p2s = @p2s + case when player = 2 then cast(card as varchar) + ',' else '' end
	from #p2 where depth = @depth
	order by id

	-- raiserror('p1: %s p2: %s depth: %d',0,0,@p1s,@p2s,@depth) with nowait

	set @winner = null

	if exists (select 1 from #seen where player = 1 and state = @p1s)
		and exists (select 1 from #seen where player = 2 and state = @p2s)
	begin
		-- raiserror('Seen p1: %s p2: %s depth: %d before, Player 1 wins!',0,0,@p1s,@p2s,@depth) with nowait

		set @winner = 1
	end
	else
		insert into #seen
		values (1, @p1s, @depth), (2, @p2s, @depth)

	if @p1id is null or @p2id is null or @winner is not null
	begin
		if @depth = 0
			break
		else
		begin
			if @winner is null
				select @winner = case when @p1id is null then 2 else 1 end

			select 
				@p1id = max(case when p.player = 1 then p.id else null end), 
				@p2id = max(case when p.player = 2 then p.id else null end), 
				@p1 = max(case when p.player = 1 then card else null end), 
				@p2 = max(case when p.player = 2 then card else null end)  
			from (select player, min(id) id, count(*) c from #p2 where depth = @depth-1 group by player) pmn
			join #p2 p
				on p.id = pmn.id

			if @winner = 1
				insert into #p2 (player,card,depth)
				values (1,@p1,@depth-1),(1,@p2,@depth-1)
			else
				insert into #p2 (player,card,depth)
				values (2,@p2,@depth-1),(2,@p1,@depth-1)

			delete #p2 where id in (@p1id,@p2id)
			delete #p2 where depth = @depth
			delete #seen where depth = @depth
				
			set @depth -= 1
		end
	end

	else if @p1c > @p1 and @p2c > @p2
	begin
		-- setup a recurse game
		insert into #p2 (player,card, depth)
		select player, card, @depth+1
		from (
			select player, card, id, ROW_NUMBER() over (partition by player order by id) c
			from #p2
			where depth = @depth
			) as x
		where c between 2 and case when player = 1 then @p1+1 else @p2+1 end
		order by id

		set @depth += 1 
	end
	else
	begin

		if @p1 > @p2
			insert into #p2 (player,card,depth)
			values (1,@p1,@depth),(1,@p2,@depth)
		else
			insert into #p2 (player,card,depth)
			values (2,@p2,@depth),(2,@p1,@depth)

		delete #p2 where id in (@p1id,@p2id)
	end

end

set @score = 0
select @score = @score + card * ROW_NUMBER() over (order by id desc) from #p2 
select @score part1

