/* Data analysis easy type*/
--Retrive the names of all track that have more than 1billion streams.
select * 
from spotify
where Stream > 1000000000;


--list all the album with there respective artist.
select distinct  Album 
from spotify
order by 1;


--Get the total no of comments for tracks where licenses = True
select sum(comments) as total_comments
from spotify
where Licensed = 1;


--Find all the tracks that belongs to the album type single
select *
from spotify
where Album_type = 'single';


--Count the total no of track by each artist
select 
Artist,
count(*) as total_tracks
from spotify
group by Artist



select 
album,
high_energy - low_energy as energy_differences
from energy_level
order by Album
