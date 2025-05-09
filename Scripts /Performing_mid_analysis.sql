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

