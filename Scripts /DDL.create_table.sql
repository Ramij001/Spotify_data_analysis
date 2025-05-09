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


/* Medium Level*/
-- Calculate the average danceability of tracks in each album.
select 
Album,
avg(Danceability) as avg_dancebility
from spotify
group by Album
order by avg(Danceability) desc


--Find the top 5 tracks with the highest energy values.
select top 5
Track,
max(Energy) as max_energy
from spotify
group by Track
order by max(Energy) desc


--List all tracks along with their views and likes where official_video = 1.
select
Track,
sum(Views) as total_views,
sum(Likes) as total_likes
from spotify
where official_video = 1
group by track
order by 2 desc

 
--For each album, calculate the total views of all associated tracks.
select 
Album,
Track,
sum(Views)
from spotify
group by Album, Track
order by sum(Views) desc


--Retrieve the track names that have been streamed on Spotify more than YouTube.
select * from

(SELECT 
    Track,
    coalesce(SUM(CASE WHEN most_playedon = 'Youtube' THEN Stream END),0) AS youtube_streams,
    isnull(SUM(CASE WHEN most_playedon = 'Spotify' THEN Stream end),0) AS spotify_streams
FROM spotify
GROUP BY Track
) as t1

where spotify_streams > youtube_streams and youtube_streams <> 0

/*Advanced Level*/
--Find the top 3 most-viewed tracks for each artist using window functions.
with Ranking_artist as
(
select
Artist,
Track,
sum(Views) as total_views,
DENSE_RANK() over(partition by Artist order by sum(Views)desc) as rank
from spotify
group by Artist,Track
) 
select * from Ranking_artist
where rank <= 3 
order by Artist,total_views desc


--Write a query to find tracks where the liveness score is above the average.
--#1 
select * from spotify
where Liveness > (select AVG(Liveness) from spotify);
--#2
with avg_live as
(
select avg(Liveness) as avg_live
from spotify
)
select s.*
from spotify s, avg_live a
where s.Liveness > a.avg_live
--#3
select *, (select avg(Liveness)from spotify) as avg_liveness
from spotify s
where s.Liveness > (select avg(Liveness) from spotify)

--Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
with energy_level as (
select 
Album,
max(Energy) as high_energy,
min(Energy) as low_energy
from spotify
group by Album
)
select 
album,
high_energy - low_energy as energy_differences
from energy_level
order by Album
