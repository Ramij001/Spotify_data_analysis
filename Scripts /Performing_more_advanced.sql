use spotify
select * from spotify;
-- Optimal Track Length Analysis
with length as (
	select
	case when Duration_min < 2.5 then 'Short'
		 when Duration_min between 2.5 and 3.5 then 'Medium'
		 else 'Long'
	end as Length_category,
	avg(Views) as avg_views,
	avg(Danceability) as avg_dancebility
	from spotify
	group by case when Duration_min < 2.5 then 'Short'
				  when Duration_min between 2.5 and 3.5 then 'Medium'
				  else 'Long' 
			  end
)
select * from length
order by avg_views

-- Platform Performance Comparison
SELECT
  most_playedon,
  COUNT(*) AS track_count,
  AVG(CAST(Views AS bigint)) AS avg_view,
  AVG(CAST(Likes AS bigint)) AS avg_like,
  SUM(CAST(Stream AS bigint)) AS total_stream
FROM spotify
GROUP BY most_playedon
ORDER BY total_stream DESC;

 -- Audio Features by Album Type
 select 
 Album_type,
 avg(Danceability) as avg_dancebility,
 avg(Energy) as avg_energy,
 avg(Valence) as avg_valence,
 avg(Tempo) as avg_tempo,
 avg(Loudness) as avg_loudness
 from spotify
 group by Album_type
 order by avg_energy;

 -- Licensed vs Unlicensed Content Performance

with licenced_avg as (
			select 
			avg(Views) as avg_licenced_view
			from spotify
			where Licensed = 1
 )
	select
			Licensed,
			case when Licensed = 1 then 'Licensed' else 'Unlicensed' end as Licence_status,
			count(*) as total_count,
			avg(Stream) as avg_streams,
			avg(Views)as avg_view,
			AVG(CAST(Likes AS bigint)) AS avg_like,
			avg(Comments) as avg_com,
			avg(Views)/(select coalesce(avg_licenced_view, 0) from licenced_avg) as relative_avg_performance
	from spotify
	group by Licensed
	order by avg_streams desc;

--Top Performing Artists Across Metrics
select 
	Artist,
	count(*) as total_count,
	sum(Views) as total_views,
	sum(Likes) as total_likes,
	sum(Comments) as total_comments,
	sum(stream) as total_stream,
	DENSE_RANK() over (order by sum(views)) as views_rank,
	DENSE_RANK() over (order by sum(stream)) as stream_rank
from spotify
group by Artist
order by total_views desc


--Video Presence Impact Analysis
select
official_video,
count(*) as total_count,
avg(Views) as toal_views,
avg(cast(Likes as bigint)) as total_likes,
avg(stream) as total_stream,
	(
	select
	avg(Views)
	from spotify
	where official_video = 1 ) / 
	(
	select
	AVG(Views)
	from spotify
	where official_video = 0 ) as video_boost_factor

from spotify
group by official_video
order by total_likes



--Optimal Audio Feature Combinations
with features_combo as
( select
NTILE(5) over(order by Danceability) as danceability_quantile,
NTILE(5) over(order by Energy) as energy_quantile,
NTILE(5) over(order by Valence) as valence_quantile,
Views,
Stream
from spotify ),

 median_calculation as
( select 
danceability_quantile,
energy_quantile,
valence_quantile,
views,
PERCENTILE_CONT(0.5) within group (order by Views) 
over(partition by danceability_quantile, energy_quantile, valence_quantile) as median_value
from features_combo )

select
fc.danceability_quantile,
fc.energy_quantile,
fc.valence_quantile,
avg(fc.views) as avg_views,
avg(fc.Stream) as avg_stream,
max(median_value) as max_median_value
from features_combo fc
JOIN median_calculation mc on mc.danceability_quantile = fc.danceability_quantile 
                           and mc.energy_quantile = fc.energy_quantile
						   and mc.valence_quantile = fc.valence_quantile
group by fc.danceability_quantile,
		 fc.energy_quantile,
		 fc.valence_quantile
order by avg_stream desc



--Outlier Detection in Engagement Metrics
with engagement as (
SELECT 
Title,
Artist,
Comments,
Likes,
Views,
(Likes*100.0/nullif(views,0)) as like_rate,
(Comments*100.0/coalesce(views,0)) as comment_rate,
avg(Likes*100.0/nullif(views,0)) over () as avg_like_rate,
avg(Comments*100.0/nullif(Views,0)) over () as avg_comment_rate,
STDEV(Likes*100.0/nullif(Views,0)) over () as std_like_rate,
STDEV(Comments*100.0/nullif(views,0)) over () as std_comments_rate
FROM spotify
where Views > 10000
)
select
Title,
Artist,
Comments,
Likes,
Views,
(like_rate - avg_like_rate)/std_like_rate as like_rate_zscore,
(comment_rate - avg_comment_rate) / std_comments_rate as comment_rate_zscore,
case 
	when (like_rate - avg_like_rate) / std_like_rate > 3 then 'like outlier'
	when (comment_rate - avg_comment_rate) / std_comments_rate > 3 then 'comment outlier'
	else 'normal'
end outlier_status
from engagement
where (like_rate - avg_like_rate) / std_like_rate > 3 or
	  (comment_rate - avg_comment_rate) / std_comments_rate > 3
order by like_rate_zscore, comment_rate_zscore


--Market Segmentation by Audio Features
with normalozation as (
select
Track,
Artist,
Views,
Danceability - min(Danceability) over() /
nullif(max (Danceability) over () - min(Danceability) over (),0) as norm_dance,
Energy - min(Energy) over () /
coalesce(max(Energy) over () - min(Energy) over (),0) as norm_energy,
Valence - min(Valence) over () /
coalesce(max(Valence) over () - min(Valence) over (),0) as norm_val,
Tempo - min(Tempo) over () /
nullif(max(Tempo) over () - min (Tempo) over (),0) as norm_tempo
from spotify
),
clustere as (
select
Track,
Artist,
Views,
NTILE(10) over (order by norm_dance) as dance_grp,
NTILE(10) over (order by norm_energy) as energy_grp,
NTILE(10) over (order by norm_val) as val_grp,
NTILE(10) over (order by norm_tempo) as tempo_grp
from normalozation
)
select
c.Track,
c.Artist,
c.Views,
CONCAT(c.dance_grp, '-', c.energy_grp, '-', c.val_grp, '-', c.tempo_grp) as feature_cluster,
s.Danceability,
s.Energy,
s.Valence,
s.Tempo
from clustere c
join spotify s on c.Track = s.Track and c.Artist = s.Artist
order by c.Views desc


-- Cross-Platform Performance Analysis
SELECT 
s1.Title,
s1.Artist,
s1.Channel as platform1,
s2.Channel as platform2,
s1.Views as platform1,
s2.views as platform2,
s1.Views / coalesce(s2.views,0) as cross_platfrom_ratio,
s1.Likes as platform1,
s2.Likes as platform2
from spotify s1
join spotify s2 on s1.Title = s2.Title and s1.Artist = s2.Artist
where s1.Channel <> s2.Channel
and s1.Views > 10000
and s2.Likes > 10000
order by cross_platfrom_ratio desc
 

-- Predictive Features for Viral Success
with percent_view as (
	select
	distinct PERCENTILE_CONT(0.9) within group(order by Views) over () as percent_90
	from spotify
),
viral_track as (
	select s.*,
	case when s.Views > (select top 1 percent_90 from percent_view)
		 then 1 
		 else 0
	end as is_viral
	from spotify s
),
viral_stats as (
	select
	'Danceability' as features,
	(avg(1.0*Danceability*is_viral) - avg(1.0*Danceability) * avg(1.0*is_viral)) / coalesce((STDEV(1.0*Danceability) * STDEV(1.0*is_viral)),0) as corelation,
	avg(case when is_viral = 1 then 1.0*Danceability end) as viral_vag,
	avg(case when is_viral = 0 then 1.0*Danceability end) as non_viral_vag
	from viral_track

	union all

	select 
	'Energy',
	(avg(1.0*Energy*is_viral) - avg(1.0*Energy) * avg(1.0*is_viral)) / isnull((stdev(1.0*Energy) * stdev(1.0*is_viral)),0),
	avg(case when is_viral = 1 then 1.0*Energy end),
	avg(case when is_viral = 0 then 1.0*Energy end)
	from viral_track

	union all 

	select
	'Duration_min',
	(avg(1.0*Duration_min*is_viral) - avg(1.0*Duration_min) * avg(1.0*is_viral)) / isnull((stdev(1.0*Duration_min) * stdev(1.0*is_viral)),0),
	avg(case when is_viral = 1 then 1.0*Duration_min end),
	avg(case when is_viral = 0 then 1.0*Duration_min end)
	from viral_track
)
select
features,
corelation,
viral_vag,
non_viral_vag
from viral_stats
where viral_vag is not null
order by corelation desc


--Sentiment-Energy Matrix Analysis
with averages as (
	select
	avg(Energy) as avg_energy,
	avg(Valence) as avg_val
	from spotify
)
SELECT 
	case when Energy > a.avg_energy and Valence > a.avg_val then 'High energy positive'
		 when Energy > a.avg_energy and Valence <= a.avg_val then 'High energy negative'
		 when Energy <= a.avg_energy and Valence > a.avg_val then 'Low energy positive'
		 else 'Low energy negative'
	end as Energy_matrix,
	count(*) as total_count,
	avg(Views) as avg_views,
	avg(Views*1.0/nullif(Likes,0))*100 as engagement_rate,
	avg(Views*1.0/nullif(Comments,0))*100 as comment_rate
from spotify, averages a
group by case when Energy > a.avg_energy and Valence > a.avg_val then 'High energy positive'
			  when Energy > a.avg_energy and Valence <= a.avg_val then 'High energy negative'
			  when Energy <= a.avg_energy and Valence > a.avg_val then 'Low energy positive'
			  else 'Low energy negative'
		 end
order by avg_views desc


--Cross-Genre Audio Feature Benchmarking
with genre as (
	select 
	Album_type as genre,
	avg(Danceability) as avg_dance,
	avg(Energy) as avg_energy,
	avg(Valence) as avg_valence,
	avg(Tempo) as avg_tempo,
	avg(Views) as avg_view
	from spotify
	group by Album_type
),
zscore as (
	select 
	genre,
	avg_dance,
	avg_dance - AVG(avg_dance) over() / (STDEV(avg_dance) over()) as dance_zscore,
	avg_energy,
	avg_energy - avg(avg_energy) over() / STDEV(avg_energy) over() as energy_zscore,
	avg_valence,
	avg_valence- avg(avg_valence) over() / STDEV(avg_valence) over() as valence_zscore,
	avg_view
	from genre
)
select
	genre,
	avg_dance,
	dance_zscore,
	avg_energy,
	energy_zscore,
	avg_valence,
	valence_zscore,
	RANK() OVER (ORDER BY avg_view desc) as view_rank
from zscore
order by view_rank 
;


--Content Performance Prediction Model Features
with data as (
	select 
	Artist,
	Track,
	Danceability,
	Energy,
	Loudness,
	Speechiness,
	Liveness,
	Valence,
	Tempo,
	Duration_min,
	EnergyLiveness,
	Views,
	Comments,
	Likes,
	Stream,
	case when Views > 0 then log(views) else null end as log_view,
	log(Views + 1) as log_views1,
	ntile(5) over(order by views) as view_q
	from spotify
	where Views > 0
)
select
	(avg(Danceability * log_view) - avg(Danceability) * avg(log_view)) / (STDEV(Danceability) * stdev(log_view)) as dance_corr,
	(avg(Energy * log_view) - avg(Energy) * avg(log_view)) / (stdev(Energy) * stdev(log_view)) as energy_corr,
	(avg(Loudness * log_view) - avg(Loudness) * avg(log_view)) / (STDEV(Loudness) * STDEV(log_view)) as loudness_corr,
	(avg(Speechiness * log_view) - avg(Speechiness) * avg(log_view)) / (STDEV(Speechiness) * STDEV(log_view)) as speech_corr,
	(avg(Liveness * log_view) - avg(Liveness) * avg(log_view)) / (STDEV(Liveness) * STDEV(log_view)) as liveness_corr,
	(avg(Valence * log_view) - AVG(Valence) * avg(log_view)) / (STDEV(Valence) * STDEV(log_view)) as val_corr,
	(avg(Tempo * log_view) - avg(Tempo) * avg(log_view)) / (STDEV(Tempo) * stdev(log_view)) as trmpo_corr,
	(avg(Duration_min * log_view) - avg(Duration_min) * avg(log_view)) / (STDEV(Duration_min) * STDEV(log_view)) as dur_min_corr,
	(avg(EnergyLiveness * log_view) - avg(EnergyLiveness) * avg(log_view)) / (STDEV(EnergyLiveness) * STDEV(log_view)) as energyliveness_corr
from data
;
