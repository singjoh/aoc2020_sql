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
('mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X'),
('mem[8] = 11'),
('mem[7] = 101'),
('mem[8] = 0')

-- */
/*
insert into #raw 
values 
('mask = 000000000000000000000000000000X1001X'),
('mem[42] = 100'),
('mask = 00000000000000000000000000000000X0XX'),
('mem[26] = 1')
--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day14.txt'


-- nuild a nice table of instructions
drop table if exists #instruct

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select id, case when isMask = 1 then val else null end mask, address, case when isMask <> 1 then cast(val as int) else null end val  
into #instruct
from (
	select	rown id, 
			max(case when id = 1 and item = 'mask' then 1 else 0 end) isMask,
			max(case when id = 1 and item <> 'mask' then cast(SUBSTRING(item,5,len(item)-5) as int) else null end) address,
			max(case when id = 3 then item end) val
	-- into #moves
	from cte_raw r
	outer apply (select * from dbo.fn_split(s,' ')) as x
	group by rown
) as x

update i
set mask = i2.mask
from #instruct i
outer apply (select top 1 * from #instruct where mask is not null and id < i.id order by id desc) i2
where i.mask is null

-- part 1, 
-- use bitwise operations on mask/value to get the true values
-- find the last time the address gets updated
-- sum those items
select sum(
		val 
		& dbo.BinaryToDecimal(replace(replace(mask, '1','0'),'X','1')) 
		| dbo.BinaryToDecimal(replace(mask, 'X','0'))
		) as part1
from
	(select distinct address from #instruct) as u
outer apply (select top 1 id from #instruct where address = u.address order by id desc) as il
join #instruct i
	on i.id = il.id

-- part 2, 
-- extract the 'not X' part of the address

drop table if exists #part2
select id, mask, address & dbo.BinaryToDecimal(replace(replace(mask, '0','1'),'X','0')) rootaddress
into #part2
from #instruct i
where address is not null

-- scan the mask for 'X', then replace with 0/1 (and delete the X
declare @i int = 0
while @i < 36
begin
	set @i += 1
	insert into #part2
	select id, substring(mask,1,@i-1) + b + substring(mask,@i+1,100), rootaddress
	from #part2 
	cross join (select '0' b union select '1') as bits
	where substring(mask,@i,1) = 'X'

	delete #part2 
	where substring(mask,@i,1) = 'X'

end

-- and just sum the values of the last instruction to update an address
;with cte as (
	select id, rootaddress | dbo.BinaryToDecimal(mask) address
	from #part2 )
select sum(cast(val as bigint)) part2 
from
	(
	select address, max(id) id from cte
	group by address
	) as il
join #instruct i	
	on i.id = il.id

