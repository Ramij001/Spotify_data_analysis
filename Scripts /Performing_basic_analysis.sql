use spotify
select count(distinct artist) from spotify

select distinct album_type from spotify

select max(duration_min) from spotify

select min(duration_min) from spotify

select count(*) from spotify

select * from spotify
where Duration_min = 0

delete from spotify
where Duration_min = 0

select distinct Channel
from spotify

select distinct most_playedon
from spotify


