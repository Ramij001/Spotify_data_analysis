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
