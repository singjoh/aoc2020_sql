

set nocount on
SET ANSI_WARNINGS OFF
go
/*


*/
use aoc2020
go

declare @mod bigint = 20201227
declare @card_public bigint = 13233401
declare @door_public bigint = 6552760

declare @val bigint, @key bigint, @subject_number bigint
set @val= 1
set @key = 1
set @subject_number = 7

while @val != @card_public
begin
	-- continue looping until we find the card publuic key, we've then looped 'loop size times'
	set @val = (@val * @subject_number) % @mod
	-- at the same time we'll determine the encryption key,
	-- thus when we find the loop size, we've already transformed door public by that key
	set @key = (@key * @door_public) % @mod
end

select @key part1
