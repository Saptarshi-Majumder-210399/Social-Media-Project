-- Objective Questions

-- Ans - 1
-- Finding duplicates


SELECT 
    COUNT(*), COUNT(DISTINCT id)
FROM
    comments;
SELECT 
    COUNT(*), COUNT(DISTINCT id)
FROM
    photos;
SELECT 
    COUNT(*), COUNT(DISTINCT id)
FROM
    tags;
SELECT 
    COUNT(*), COUNT(DISTINCT id)
FROM
    users;
with cte1 as (
SELECT *, DENSE_RANK() Over(partition by follower_id,followee_id) as rnk
from
follows
)
SELECT 
    *
FROM
    cte1
WHERE
    rnk > 1;

SELECT 
    user_id, photo_id, created_at, COUNT(*) AS cnt_duplicates
FROM
    likes
GROUP BY 1 , 2 , 3
HAVING COUNT(*) > 1;

SELECT 
    *, COUNT(*) AS cnt_duplicates
FROM
    photo_tags
GROUP BY 1 , 2
HAVING COUNT(*) > 1;




-- Ans-2
-- Users Activity levels

with likes_per_users as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_users as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
posts_per_users as (
select user_id,count(image_url) as num_photos
from photos
group by 1
)
SELECT 
    username AS Users_Name,
    num_likes,
    num_photos,
    num_coments_on_posts,
    (num_likes + num_coments_on_posts + num_photos) AS Users_activity_level
FROM
    users u
        JOIN
    likes_per_users c1 ON u.id = c1.user_id
        JOIN
    comments_per_users c2 ON u.id = c2.user_id
        JOIN
    posts_per_users c3 ON u.id = c3.user_id
ORDER BY 1;



-- Ans - 3
-- Avg no. of tags per posts

with Avg_tags as (
 SELECT 
    photo_id, COUNT(tag_id) AS num_tags_per_posts
FROM
    photos p
        JOIN
    photo_tags t ON p.id = t.photo_id
GROUP BY 1
)
SELECT 
    AVG(num_tags_per_posts) AS avg_num_tags_per_posts
FROM
    Avg_tags;



-- Ans - 4
-- Engagement Rankings

with likes_per_users as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_users as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
 user_based_engagement as(
SELECT 
    username AS Platform_Users,
    SUM(num_coments_on_posts + num_likes) AS Engagement_rate
FROM
    users u
        JOIN
    likes_per_users c1 ON u.id = c1.user_id
        JOIN
    comments_per_users c2 ON u.id = c2.user_id
GROUP BY 1
)
SELECT *, DENSE_RANK() OVER(ORDER BY Engagement_rate DESC) AS User_Engagement_ranking
FROM 
user_based_engagement
ORDER BY 3;


-- Ans - 5
-- Rankings highest followers and followings

with user_followee as (
SELECT 
    id, COUNT(DISTINCT followee_id) AS num_followee
FROM
    users u
        LEFT JOIN
    follows f ON f.follower_id = u.id
GROUP BY 1
),
user_followers as (
SELECT 
    id, COUNT(DISTINCT follower_id) AS num_follower
FROM
    users u
        LEFT JOIN
    follows f ON f.followee_id = u.id
GROUP BY 1
)
SELECT 
    username AS Platform_Users, num_followee, num_follower,
    DENSE_RANK() OVER(ORDER BY num_followee desc,num_follower desc) as Users_rank_based_on_followers_followings
FROM
    users u
        LEFT JOIN
    user_followee ufe ON u.id = ufe.id
        LEFT JOIN
    user_followers ufs ON u.id = ufs.id;



-- Ans- 6
-- Avg Engagement rate

with likes_per_post as (
SELECT 
    id, COUNT(photo_id) AS num_likes
FROM
    likes l
        JOIN
    photos p ON l.photo_id = p.id
GROUP BY 1
),
comments_per_post as (
SELECT 
    photo_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
Avg_Engagement_rate_per_user as (
SELECT 
    username AS Users_Name,
    p.id AS Post_id,
    ROUND(AVG(num_likes + num_coments_on_posts), 2) AS Avg_Engagement_rate
FROM
    photos p
        JOIN
    likes_per_post c1 ON p.id = c1.id
        JOIN
    comments_per_post c2 ON p.id = c2.photo_id
        JOIN
    users u ON p.user_id = u.id
GROUP BY 1 , 2
)
SELECT 
    *
FROM
    Avg_Engagement_rate_per_user
ORDER BY 2 DESC;





-- Ans - 7
-- Users who never liked any photos

With Users_Never_Liked as (
select distinct user_id from likes
)
SELECT 
    username AS Users_Never_Liked_Any_Photo
FROM
    users u
        LEFT JOIN
    Users_Never_Liked u1 ON u.id = u1.user_id
WHERE
    u1.user_id IS NULL
ORDER BY username;





-- Ans - 8
-- user-generated content 

SELECT 
    tag_name,
    COUNT(pt.photo_id) AS num_posts,
    COUNT(DISTINCT p.user_id) AS num_users,
    COUNT(l.photo_id) AS num_likes,
    (COUNT(pt.photo_id)+COUNT(DISTINCT p.user_id)+COUNT(l.photo_id)) as total_engagement_Per_Tag
FROM
    tags t
        JOIN
    photo_tags pt ON t.id = pt.tag_id
        JOIN
    photos p ON pt.photo_id = p.id
        JOIN
    likes l ON pt.photo_id = l.photo_id
GROUP BY 1
ORDER BY 2 DESC , 3 DESC;



-- Ans - 9
-- Correlations 

with likes_per_users as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_posts as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
posts_per_users as (
SELECT 
    user_id, COUNT(image_url) AS posts
FROM
    photos
GROUP BY 1
),
engagement_per_user as (
SELECT 
    username AS Users_Name,
    p.user_id,
    p.id,
    SUM(num_likes + num_coments_on_posts + posts) AS Total_Engagement_rate
FROM
    photos p
        JOIN
    likes_per_users c1 ON p.user_id = c1.user_id
        JOIN
    comments_per_posts c2 ON p.user_id = c2.user_id
        JOIN
    users u ON p.user_id = u.id
        JOIN
    posts_per_users c3 ON p.user_id = c3.user_id
GROUP BY 1 , 2 , 3
),
engagement_percentage as (
SELECT 
    Users_Name,
    SUM(ROUND(100 * (num_likes / Total_Engagement_rate),
            2)) AS num_likes_percent,
    SUM(ROUND(100 * (posts / Total_Engagement_rate), 2)) AS posts_percent,
    SUM(ROUND(100 * (num_coments_on_posts / Total_Engagement_rate),
            2)) AS comment_percent,
    SUM(ROUND(100 * (Total_Engagement_rate / Total_Engagement_rate),
            2)) AS total_engagement_percent
FROM
    engagement_per_user c4
        JOIN
    likes_per_users c1 ON c4.user_id = c1.user_id
        JOIN
    comments_per_posts c2 ON c4.user_id = c2.user_id
        JOIN
    users u ON c4.user_id = u.id
        JOIN
    posts_per_users c3 ON c4.user_id = c3.user_id
group by 1
)
SELECT *, DENSE_RANK() OVER(ORDER BY total_engagement_percent DESC,posts_percent DESC,num_likes_percent DESC) AS ranks
FROM 
	engagement_percentage
ORDER BY ranks 
limit 15;





-- Ans - 10
-- Total num of likes,comments and photo_tags

with likes_per_user as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_user as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
tags_per_user as (
SELECT 
    user_id, COUNT(tag_id) AS num_tags
FROM
    photo_tags t
        JOIN
    photos p ON t.photo_id = p.id
GROUP BY 1
),
total_based_on_users as (
SELECT 
    username,
    SUM(num_tags) AS total_num_tags,
    SUM(num_coments_on_posts) AS total_num_coments_on_posts,
    SUM(num_likes) AS total_num_likes
FROM
    users u
        JOIN
    likes_per_user c1 ON u.id = c1.user_id
        JOIN
    comments_per_user c2 ON u.id = c2.user_id
        JOIN
    tags_per_user c3 ON u.id = c3.user_id
GROUP BY 1
)
SELECT *, DENSE_RANK() OVER(ORDER BY
(total_num_tags+total_num_coments_on_posts+total_num_likes) DESC) AS ranks
FROM 
total_based_on_users;






-- Ans - 11
-- Month-Wise Engagement Ranks

with likes_per_posts as (
SELECT 
    id, COUNT(photo_id) AS num_likes
FROM
    likes l
        JOIN
    photos p ON l.photo_id = p.id
GROUP BY 1
),
comments_per_post as (
SELECT 
    photo_id, COUNT(comment_text) AS num_coments_on_posts
FROM
    comments
GROUP BY 1
),
Per_Month_Engagement_Ranking as (
SELECT 
    username AS Users_Name,
    MONTH(created_at) AS Months,
    SUM(num_likes + num_coments_on_posts) AS Total_Engagement_rate,
    DENSE_RANK() OVER(partition by month(created_at) 
    ORDER BY SUM(num_likes+num_coments_on_posts) DESC) Month_wise_engagement_rank
FROM
    photos p
        JOIN
    likes_per_posts c1 ON p.id = c1.id
        JOIN
    comments_per_post c2 ON p.id = c2.photo_id
        JOIN
    users u ON p.user_id = u.id
GROUP BY 1, MONTH(created_at)
)
SELECT 
    *
FROM
    Per_Month_Engagement_Ranking
ORDER BY 2;





-- Ans - 12
-- Hashtag with highest avg likes

with likes_per_photo as (
SELECT 
    photo_id, COUNT(user_id) AS num_likes
FROM
    likes
GROUP BY 1
),
avg_likes_per_tag_rank as (
SELECT 
    tag_name, ROUND(AVG(num_likes), 2) AS Avg_num_likes,
    dense_rank() over(order by avg(num_likes) desc) as Tag_avg_likes_rank
FROM
    likes_per_photo c1
        JOIN
    photo_tags p ON c1.photo_id = p.photo_id
        JOIN
    tags t ON t.id = p.tag_id
GROUP BY 1
)
SELECT 
    UPPER(tag_name) AS Max_liked_tag,
    Avg_num_likes AS Max_Avg_num_likes,
    Tag_avg_likes_rank
FROM
    avg_likes_per_tag_rank
WHERE
    Tag_avg_likes_rank = 1
ORDER BY 2;




-- Ans - 13
-- Users who followed after being followed

with Users_who_followed_after_being_followed as (
SELECT DISTINCT
    f1.follower_id AS user_who_followed_after,
    f1.followee_id AS followed_by
FROM
    follows f1
        JOIN
    follows f2 ON f1.followee_id = f2.follower_id
        AND f1.follower_id != f2.follower_id
WHERE
    f1.follower_id = f2.followee_id
)
SELECT DISTINCT
    username AS Later_followed_users
FROM
    Users_who_followed_after_being_followed c1
        JOIN
    users u ON c1.user_who_followed_after = u.id
ORDER BY 1;




-- Subjective Questions
-- Ans - 1

with total_likes_per_user as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
total_comments_per_user as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_per_users
FROM
    comments
GROUP BY 1
),
total_post_per_user as (
SELECT 
    user_id, COUNT(image_url) AS num_posts
FROM
    photos
GROUP BY 1
),
Users_Activity_Engagement as (
SELECT 
    username,
    SUM(num_posts + num_coments_per_users + num_likes) AS activity_level_users,
    SUM(num_coments_per_users + num_likes) AS Engagement_rate
FROM
    users u
        JOIN
    total_likes_per_user c1 ON u.id = c1.user_id
        JOIN
    total_comments_per_user c2 ON u.id = c2.user_id
        JOIN
    total_post_per_user c3 ON u.id = c3.user_id
GROUP BY 1
)
SELECT *, DENSE_RANK() over(order by activity_level_users desc,Engagement_rate) as users_ranking
FROM
    Users_Activity_Engagement
WHERE
    activity_level_users > (SELECT 
            AVG(activity_level_users)
        FROM
            Users_Activity_Engagement)
        AND Engagement_rate > (SELECT 
            AVG(Engagement_rate)
        FROM
            Users_Activity_Engagement)
            Order by 4;






-- Ans - 2
-- Inactive Users
with like_per_user as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_user as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_per_users
FROM
    comments
GROUP BY 1
),
Posts_per_user as (
SELECT 
    user_id, COUNT(image_url) AS num_posts
FROM
    photos
GROUP BY 1
),
Username_with_zero_Activity_Engagement as (
SELECT 
    username,
    SUM(num_posts + num_coments_per_users + num_likes) AS activity_level_users,
    SUM(num_coments_per_users + num_likes) AS Engagement_rate
FROM
    users u
        LEFT JOIN
    like_per_user c1 ON u.id = c1.user_id
        LEFT JOIN
    comments_per_user c2 ON u.id = c2.user_id
        LEFT JOIN
    Posts_per_user c3 ON u.id = c3.user_id
WHERE
    c1.user_id IS NULL
GROUP BY 1
)
SELECT 
    username AS Inactive_users
FROM
    Username_with_zero_Activity_Engagement
ORDER BY 1;






-- Ans - 3
-- Highest Engagement Tag

with likes_per_posts as (
SELECT 
    photo_id, COUNT(user_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_posts as (
SELECT 
    photo_id, COUNT(comment_text) AS num_coments_per_post
FROM
    comments
GROUP BY 1
),
engagement_rate_of_each_tag as(
SELECT 
    tag_name,
    SUM(num_coments_per_post + num_likes) AS Engagement_rate
FROM
    tags t
        JOIN
    photo_tags pt ON t.id = pt.tag_id
        JOIN
    likes_per_posts c1 ON pt.photo_id = c1.photo_id
        JOIN
    comments_per_posts c2 ON pt.photo_id = c2.photo_id
GROUP BY 1
)
SELECT 
    *,
    dense_rank() Over(order by Engagement_rate desc) as tag_ranking
FROM
    engagement_rate_of_each_tag;
    
    
    
    -- Ans - 4
    -- Trend between users engagement and posting times
    
with time_of_likes as (
SELECT 
    photo_id,
    TIME(created_at) AS likes_time,
    COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1 , 2
),
time_of_comments as (
SELECT 
    photo_id,
    TIME(created_at) AS comments_time,
    COUNT(comment_text) AS num_coments_per_users
FROM
    comments
GROUP BY 1 , 2
),
time_based_engagement as (
SELECT 
    TIME(created_dat) AS post_time,
    comments_time,
    likes_time,
    SUM(num_coments_per_users + num_likes) AS Engagement_rate
FROM
    photos p
        JOIN
    time_of_likes c1 ON p.id = c1.photo_id
        JOIN
    time_of_comments c2 ON p.id = c2.photo_id
GROUP BY 1 , 2 , 3
)
SELECT 
    *
FROM
    time_based_engagement
ORDER BY 1;



-- Ans - 5
-- INFLUENCER MARKETING CAMPAINGS

with Users_follow_count as (
SELECT 
    followee_id, COUNT(DISTINCT follower_id) AS Follower_count
FROM
    follows
GROUP BY 1
),
like_per_user as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_user as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_per_users
FROM
    comments
GROUP BY 1
),
Ranked_Users_for_marketing as (
SELECT 
    username AS Platform_Username,
    Follower_count,
    SUM(num_coments_per_users + num_likes) AS Engagement_rate,
    DENSE_RANK() OVER(ORDER BY SUM(num_coments_per_users + num_likes) DESC, follower_count DESC) as Rankings
FROM
    users u
        JOIN
    Users_follow_count c1 ON u.id = c1.followee_id
        JOIN
    like_per_user l ON u.id = l.user_id
        JOIN
    comments_per_user c2 ON u.id = c2.user_id
GROUP BY 1 , 2
    )
   SELECT 
    *
FROM
    Ranked_Users_for_marketing;
    
    
    
    -- Ans - 6
    -- Targeted Infulencer Marketing
    
with like_per_user as (
SELECT 
    user_id, COUNT(photo_id) AS num_likes
FROM
    likes
GROUP BY 1
),
comments_per_user as (
SELECT 
    user_id, COUNT(comment_text) AS num_coments_per_users
FROM
    comments
GROUP BY 1
),
Tags_per_user as ( 
SELECT 
    tag_name, user_id
FROM
    tags t
        JOIN
    photo_tags pt ON t.id = pt.tag_id
        JOIN
    photos p ON p.id = pt.photo_id
),
Ranked_Users_for_marketing as (
SELECT 
    username AS Platform_Username,
    tag_name as Users_Tags,
    SUM(num_coments_per_users + num_likes) AS Per_Tag_Engagement_rate,
    dense_rank() OVER(PARTITION BY username ORDER BY SUM(num_coments_per_users + num_likes) DESC) AS Users_Per_tag_ranking
FROM
    users u
        JOIN
    like_per_user l ON u.id = l.user_id
        JOIN
    comments_per_user c2 ON u.id = c2.user_id
    join
    Tags_per_user t on u.id = t.user_id
GROUP BY 1 , 2
    )
   SELECT 
    *
FROM
    Ranked_Users_for_marketing
    where Users_Per_tag_ranking = 1
ORDER BY 3 desc,1;



--- END ---