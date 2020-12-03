set nocount on
go
/*
ALTER FUNCTION [dbo].[fn_finditems]
(
	@List NVARCHAR(MAX),
	@item NVARCHAR(255)
)
RETURNS TABLE
WITH SCHEMABINDING AS
RETURN
  WITH E1(N)        AS ( SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 
                         UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 
                         UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
       E2(N)        AS (SELECT 1 FROM E1 a, E1 b),
       E4(N)        AS (SELECT 1 FROM E2 a, E2 b),
       E42(N)       AS (SELECT 1 FROM E4 a, E2 b),
       cteTally(N)  AS (SELECT 0 UNION ALL SELECT TOP (LEN(ISNULL(@List,1))) 
                         ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E42),
       cteStart(POS) AS (SELECT t.N FROM cteTally t
                         WHERE (SUBSTRING(@List,t.N,1) = @item))
	SELECT POS FROM cteStart;

*/
use aoc2020
go

drop table if exists #raw
create table #raw (s varchar(100))

--test data
/*
insert into #raw 
values
	('..##.......'),
    ('#...#...#..'),
    ('.#....#..#.'),
    ('..#.#...#.#'),
    ('.#...##..#.'),
    ('..#.##.....'),
    ('.#.#.#....#'),
    ('.#........#'),
    ('#.##...#...'),
    ('#...##....#'),
    ('.#..#...#.#"')
-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day3.txt'


drop table if exists #trees

select rown, POS coln
into #trees
from 
	(select row_number() over (order by (select null)) as rown, s
	from #raw) as x
outer apply (select * from dbo.fn_finditems(s,'#')) y

declare @gridlen int
select top 1 @gridlen = len(s) from #raw

declare @right int = 3
declare @down int = 1


declare @treec int
-- part 1 
select @treec = count(*)
from 
 (	
	-- determmine the row/col for the path taken
 	select x.rown, 1 + (((x.rown - 1)/@down) * @right ) % @gridlen coln
	from (select distinct(rown) rown from #trees where (rown -1) % @down = 0) x
 ) as p
join #trees t
	on t.rown = p.rown
	and t.coln = p.coln

select @treec 'part1'

-- part 2
drop table if exists #paths
select ROW_NUMBER() over (order by (select null))  rown, rght, down 
into #paths
from (
	select 1 rght, 1 down
	union select 3, 1
	union select 5, 1
	union select 7, 1
	union select 1, 2
	) as x

declare @row int, @maxrow int, @treeprod bigint
select @row = 0, @maxrow = max(rown) from #paths

set @treeprod = 1

while @row < @maxrow
begin
	set @row = @row + 1

	select @right = rght, @down = down
	from #paths
	where rown = @row

	select @treeprod = @treeprod * count(*)
	from 
	 (	
 		select x.rown, 1 + (((x.rown - 1)/@down) * @right ) % @gridlen coln
		from (select distinct(rown) rown from #trees where (rown -1) % @down = 0) x
	 ) as p
	join #trees t
		on t.rown = p.rown
		and t.coln = p.coln

end

select @treeprod 'part2'



