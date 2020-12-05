set nocount on
go
/*
CREATE FUNCTION [dbo].[BinaryToDecimal]
(
	@Input varchar(255)
)
RETURNS bigint
AS
BEGIN

	DECLARE @Cnt tinyint = 1
	DECLARE @Len tinyint = LEN(@Input)
	DECLARE @Output bigint = CAST(SUBSTRING(@Input, @Len, 1) AS bigint)

	WHILE(@Cnt < @Len) BEGIN
		SET @Output = @Output + POWER(CAST(SUBSTRING(@Input, @Len - @Cnt, 1) * 2 AS bigint), @Cnt)

		SET @Cnt = @Cnt + 1
	END

	RETURN @Output	

END

*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(100))

--test data
/*
insert into #raw 
values
    ('FBFBBFFRLR'),
    ('FFFBBBFRRR')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day5.txt'

drop table if exists #seats

select *
into #seats
from #raw r
outer apply (select replace(replace(replace(replace(s,'B','1'),'R','1'),'F','0'),'L','0') as b) as x
outer apply (select dbo.BinaryToDecimal(x.b) sid) as y

-- part 1, max sid
select max(sid) part1 from #seats

-- part 2, find the seat not in the list
select sid - 1 part2
from (
	select *, lag(sid) over (order by sid) psid
	from #seats
	) as x
where psid is not null 
and psid != sid - 1 