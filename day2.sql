set nocount on
go
/*


*/
use aoc2020
go


drop table if exists #raw
create table #raw (s varchar(100))

--test data
/*
insert into #raw 
values 
('1-3 a: abcde'),
('1-3 b: cdefg'),
('2-9 c: ccccccccc')

--*/
-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day2.txt'

drop table if exists #data

select z.*
into #data
from #raw r
outer apply (select CHARINDEX(' ',r.s) space1, CHARINDEX('-',r.s) dash) as x
outer apply (select CHARINDEX(' ',r.s,space1+1) space2) as y
outer apply (
	select	cast(SUBSTRING(r.s,0,dash) as int) as p1, 
			cast(SUBSTRING(r.s,dash+1,space1-dash-1) as int) as p2,
			SUBSTRING(r.s,space1+1,space2-space1-2) as ch,
			SUBSTRING(r.s,space2+1,100)as pwd
			) as z

-- part 1 
select count(*)
from #data
-- How to count occurences in a string, trim them and then see how many chars got removed
-- (only really works for standard characters)
where LEN(RTRIM(pwd)) - LEN(REPLACE(RTRIM(pwd), ch, '')) between p1 and p2

-- part 2
select count(*)
from #data 
where 
	(SUBSTRING(pwd,p1,1) = ch and SUBSTRING(pwd,p2,1) <> ch)
OR	(SUBSTRING(pwd,p1,1) <> ch and SUBSTRING(pwd,p2,1) = ch)