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
('mxmxvkd kfcds sqjhc nhms (contains dairy, fish)'),
('trh fvjkl sbzzf mxmxvkd (contains dairy)'),
('sqjhc fvjkl (contains soy)'),
('sqjhc mxmxvkd sbzzf (contains fish)')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day21.txt'

drop table if exists #foods
drop table if exists #allergens
drop table if exists #recipes


;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select row_number() over (order by (item)) as id, item
into #foods
from (
	select distinct y.item
	from cte_raw r
	outer apply (select * from dbo.fn_split(s,'(') where id = 1) as x
	outer apply (select * from dbo.fn_split(x.item,' ')) as y
) as z

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select row_number() over (order by (item)) as id, item
into #allergens
from (
	select distinct y.item
	from cte_raw r
	outer apply (select replace(replace(replace(item,',',''),'contains ',''),')','') item from dbo.fn_split(s,'(') where id = 2) as x
	outer apply (select * from dbo.fn_split(x.item,' ')) as y
) as z

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select rown, f.id food_id, a.id allergen_id
into #recipes
from cte_raw r
outer apply (
	select y.item from dbo.fn_split(s,'(') x
	outer apply (select * from dbo.fn_split(x.item,' ')) as y
	where x.id = 1
) as x
outer apply (
	select replace(replace(replace(y.item,',',''),'contains ',''),')','') item from dbo.fn_split(s,'(') x
	outer apply (select * from dbo.fn_split(x.item,' ')) as y
	where x.id = 2
) as y
join #foods f
	on f.Item = x.item
join #allergens a
	on a.Item = y.item

drop table if exists #matched
create table #matched(food_id int, allergen_id int)
drop table if exists #matches
create table #matches(food_id int, allergen_id int)


while 1=1
begin
	truncate table #matches

	-- for each allergen, check what foods match all the recipes it is included in
	-- excluding already matched foods and allergens
	insert into #matches
	select r.food_id, a.id
	from #allergens a
	outer apply (select count(distinct rown) c from #recipes where allergen_id = a.id) as x
	join #recipes r
		on r.allergen_id = a.id
	left join #matched m
		on m.food_id = r.food_id
		or m.allergen_id = a.id
	where m.food_id is null
	group by a.id, x.c, r.food_id
	having count(*) = x.c

	if @@ROWCOUNT = 0 break

	-- match the items where there was only one possible food to match
	insert into #matched
	select * from #matches
	where food_id in (select food_id from #matches group by food_id having count(*) = 1)

end

select count(*) part1 
from (select distinct rown, food_id from #recipes) r
left join #matched m
	on m.food_id = r.food_id
where m.food_id is null


declare @foodlist varchar(max) = ''

select @foodlist = @foodlist + f.Item + ','
from #matched m
join #foods f
	on f.id = m.food_id
join #allergens a
	on a.id = m.allergen_id
order by a.Item

select SUBSTRING(@foodlist,1,len(@foodlist)-1) 
