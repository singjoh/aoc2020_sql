set nocount on
go
/*
create database aoc2020
go
USE [aoc2020]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[fn_split]
(
   @List NVARCHAR(MAX),
   @Delimiter NVARCHAR(255)
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
       cteStart(N1) AS (SELECT t.N+1 FROM cteTally t
                         WHERE (SUBSTRING(@List,t.N,1) = @Delimiter OR t.N = 0))

  SELECT	Id = ROW_NUMBER() OVER (ORDER BY ((SELECT NULL))), 
			Item = SUBSTRING(@List, s.N1, ISNULL(NULLIF(CHARINDEX(@Delimiter,@List,s.N1),0)-s.N1,8000))
    FROM cteStart s;
GO

*/
use aoc2020
go


drop table if exists #raw
create table #raw (s varchar(100))

--test data
--/*
insert into #raw 
select item from dbo.fn_split('1721,979,366,299,675,1456',',') 
--*/

drop table if exists #data

select row_number() over (order by (select null)) as rown, cast(s as int) c
into #data
from #raw

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day1.txt'

-- part 1
select a.c * b.c
from #data a
join #data b
	on b.rown > a.rown
where a.c + b.c = 2020

-- part 2
select a.c * b.c * c.c
from #data a
join #data b
	on b.rown > a.rown
join #data c
	on c.rown > b.rown
where a.c + b.c + c.c = 2020
