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
    ('ecl:gry pid:860033327 eyr:2020 hcl:#fffffd'),
    ('byr:1937 iyr:2017 cid:147 hgt:183cm'),
    (''),
    ('iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884'),
    ('hcl:#cfa07d byr:1929'),
    (''),
    ('hcl:#ae17e1 iyr:2013'),
    ('eyr:2024'),
    ('ecl:brn pid:760753108 byr:1931'),
    ('hgt:179cm'),
    (''),
    ('hcl:#cfa07d eyr:2025 pid:166559648'),
    ('iyr:2011 ecl:brn hgt:59in')

-- */

-- real data
bulk insert #raw from 'C:\Users\john_\OneDrive\Documents\SQL Server Management Studio\Aoc2020\day4.txt'

drop table if exists #pwds

;with cte_raw(rown,s) as
	(select row_number() over (order by (select null)) as rown, isnull(s,'')
	from #raw)
select x.id, max(case when z.id = 1 then z.item else null end) k, max(case when z.id = 2 then z.item else null end) v
into #pwds
from cte_raw r
outer apply (select 1+count(*) id from cte_raw where rown < r.rown and len(s) = 0) as x
outer apply (select * from dbo.fn_split(s,' ')) as y 
outer apply (select * from dbo.fn_split(y.item,':')) as z
where len(s) > 0 
group by x.id, r.rown, y.id

-- part 1, need to have the 7 fields present, if not delete those
delete p
from #pwds p
left join (
	select id
	from #pwds
	where k in ('byr','iyr','eyr','hgt','hcl','ecl','pid')
	group by id 
	having count(*) = 7
) as x
	on p.id = x.id
where x.id is null

select count(distinct id) part1 from #pwds

-- part 2, delete items where a rule fails
-- three year fields, numeric and have defined ranges
delete p
from #pwds p
left join (
	select *
	from (
		select id, 
			max(case k when 'byr' then v else null end) byr,
			max(case k when 'iyr' then v else null end) iyr,
			max(case k when 'eyr' then v else null end) eyr
		from #pwds
		where k in ('byr','iyr','eyr')
		and ISNUMERIC(v) = 1
		group by id) as x
	where byr between 1920 and 2002 
	and iyr between 2010 and 2020
	and eyr between 2020 and 2030
) as x
	on p.id = x.id
where x.id is null

-- hgt is cm or in and has a defined range
delete p
from #pwds p
left join (
	select *
	from (
		select id, right(v,2) unit, cast(substring(v,1,len(v)-2) as int) hgt
		from #pwds
		where k = 'hgt'
		and isnumeric(substring(v,1,len(v)-2)) = 1
	) as x
	where (unit = 'cm' and hgt between 150 and 193)
	or (unit = 'in' and hgt between 59 and 76)
) as x
	on p.id = x.id
where x.id is null

-- hair is # followed by 6 hex chars, i.e. anything where we don't match a list of other chars
delete p
from #pwds p
left join (
	select *
	from #pwds
	where k = 'hcl'
	and left(v,1) = '#'
	and len(substring(v,2,100)) = 6
	and substring(v,2,100) not like '%[^0-9A-F]%'
) as x
	on p.id = x.id
where x.id is null

-- eyes are a particular include list
delete p
from #pwds p
left join (
	select *
	from #pwds
	where k = 'ecl'
	and v in ('amb','blu','brn','gry','grn','hzl','oth')
) as x
	on p.id = x.id
where x.id is null

-- pwd id 9 nnumber chars, i.e. anything where we don't match a list of all other chars
delete p
from #pwds p
left join (
	select *
	from #pwds
	where k = 'pid'
	and len(v) = 9
	and v not like '%[^0-9]%'
) as x
	on p.id = x.id
where x.id is null

-- see whats left
select count(distinct id) part2 from #pwds
