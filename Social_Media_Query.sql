-- Use database
use socialmedia;

-- Size of data in each table
SELECT 	table_name, table_rows
FROM	INFORMATION_SCHEMA.tables
WHERE	TABLE_SCHEMA = 'socialmedia';


-- How many posts did each user make?

SELECT	u.user_id, 
		u.username, 
        COUNT(*) AS number_of_posts
FROM	users u
        JOIN post p 
		  ON u.user_id = p.user_id
GROUP BY user_id , username
ORDER BY number_of_posts desc;


-- How many users have registered on the platform?

SELECT 	COUNT(user_id) AS number_of_registered_users
FROM    users;


-- How many users have not updated their profile picture?

SELECT Count(profile_photo_url) AS Empty_profile_picture_counts
FROM   users
WHERE  profile_photo_url IS NULL; 


-- What is the average number of posts per user?

SELECT Round(Avg(number_of_posts),0) avg_number_of_posts
FROM   (SELECT u.user_id,
               u.username,
               Count(*) AS number_of_posts
        FROM   users u
               JOIN post p
                 ON u.user_id = p.user_id
        GROUP  BY u.user_id, u.username) t; 

        
-- Which users have the highest number of followers?

WITH FollowersDetails AS 
(	SELECT 	u.user_id,
			u.username,
			Count(f.follower_id) AS followers_count,
			Dense_rank() OVER (ORDER BY Count(f.follower_id) DESC) AS followers_rank
	FROM	users u
			JOIN follows f
			  ON u.user_id = f.followee_id
	GROUP  BY u.user_id, u.username
	ORDER  BY followers_count DESC)
SELECT user_id,	username, followers_count
FROM   FollowersDetails
WHERE  followers_rank = 1; 


-- Which users have the most comments on their posts?

WITH UsersCommentsCount AS
(
	SELECT u.user_id,
		   u.username,
		   Count(c.comment_id) AS comments_count,
		   Dense_rank() OVER (ORDER BY Count(c.comment_id) DESC) AS comments_rank
	FROM   users u
	JOIN   post p	    ON	u.user_id = p.user_id
	JOIN   comments c 	ON 	p.post_id = c.post_id
	GROUP  BY u.user_id, u.username
	ORDER  BY comments_count DESC
)
SELECT user_id, username, comments_count
FROM   UsersCommentsCount
WHERE  comments_rank = 1;


-- What are the top 10 most liked posts?

SELECT p.post_id,
       Count(pl.user_id) AS number_of_likes
FROM   post p
       LEFT JOIN post_likes pl
              ON p.post_id = pl.post_id
GROUP  BY p.post_id
ORDER  BY number_of_likes DESC
LIMIT  10; 


-- Which posts have received the most comments?
SELECT post_id
FROM   (SELECT p.post_id,
               Count(c.comment_id)                    				 AS number_of_comments,
               Dense_rank()	OVER (ORDER BY Count(c.comment_id) DESC) AS comments_rank
        FROM   post p
               LEFT JOIN comments c
					  ON p.post_id = c.post_id
        GROUP  BY p.post_id
        ORDER  BY number_of_comments DESC) t
WHERE  comments_rank = 1; 
	
        
-- What is the average number of likes per post?

SELECT Round(Avg(number_of_likes_per_post), 0) AS avg_likes_per_post
FROM   (SELECT p.post_id,
               Count(pl.user_id) AS number_of_likes_per_post
        FROM   post p
               JOIN post_likes pl
					  ON p.post_id = pl.post_id
        GROUP  BY p.post_id) t;
        

-- How many posts contain a specific hashtag (e.g., #joinbtsarmy)?

SELECT Count(p.post_id) AS number_of_posts
FROM   post p
       JOIN post_tags pt
		 ON p.post_id = pt.post_id
       JOIN hashtags h
		 ON pt.hashtag_id = h.hashtag_id
WHERE  h.hashtag_name = ' #joinbtsarmy'; 


-- How many comments have been made in total?

SELECT Count(*) AS total_comments
FROM   comments; 


-- Which comments have received the most likes?

SELECT c.comment_id,
       comment_text,
       Count(*) AS number_of_likes
FROM   comments c
       LEFT JOIN comment_likes cl
              ON c.comment_id = cl.comment_id
GROUP  BY c.comment_id, comment_text
ORDER  BY number_of_likes DESC
LIMIT  1; 


-- What is the average number of comments per post?

SELECT Round(Avg(no_of_comments)) AS avg_no_of_comments
FROM   (SELECT p.post_id,
               Count(c.comment_id) AS no_of_comments
        FROM   post p
               LEFT JOIN comments c
                      ON p.post_id = c.post_id
        GROUP  BY p.post_id) t; 
        
        
-- How many comments did a specific user make?

SELECT u.user_id,
       Count(c.comment_id) AS comments_count
FROM   users u
       LEFT JOIN comments c
              ON u.user_id = c.user_id
GROUP  BY u.user_id
ORDER  BY u.user_id; 


-- What is the total number of likes received by all users?

SELECT Sum(number_of_likes) AS total_likes
FROM   (SELECT u.user_id,
               u.username,
               Count(pl.user_id) AS number_of_likes
        FROM   users u
               JOIN post p
                 ON u.user_id = p.user_id
               JOIN post_likes pl
                 ON p.post_id = pl.post_id
        GROUP  BY u.user_id, u.username) t; 


-- What is the total number of comments received by all users?

SELECT Sum(number_of_comments) AS total_comments
FROM   (SELECT u.user_id,
			   u.username,
			   Count(c.comment_id) AS number_of_comments
		FROM   users u
			   JOIN post p
				 ON u.user_id = p.user_id
			   JOIN comments c
				 ON p.post_id = c.post_id
		GROUP  BY u.user_id, u.username) t;
        
       
-- Which user has the highest engagement rate (likes + comments)?

WITH UsersCommentsCount AS (
SELECT u.user_id,
	   u.username,
	   Count(c.comment_id) AS number_of_comments
FROM   users u
	   JOIN post p
		 ON u.user_id = p.user_id
	   JOIN comments c
		 ON p.post_id = c.post_id
GROUP  BY u.user_id, u.username),

UsersLikesCount AS (
SELECT u.user_id,
	   u.username,
	   Count(pl.user_id) AS number_of_likes
FROM   users u
	   JOIN post p
		 ON u.user_id = p.user_id
	   JOIN post_likes pl
		 ON p.post_id = pl.post_id
GROUP  BY u.user_id, u.username)

SELECT   likes.user_id,
         likes.username,
         Round(((number_of_likes + number_of_comments)/(Sum(number_of_likes + number_of_comments) OVER()))*100, 2) AS engagement_rate
FROM     UsersLikesCount likes
JOIN     UsersCommentsCount comments
ON       likes.user_id = comments.user_id
ORDER BY engagement_rate DESC limit 1;


-- What are the top 10 most used hashtags?

SELECT h.hashtag_id,
       h.hashtag_name,
       Count(pt.post_id) AS hashtags_used_counts
FROM   hashtags h
       JOIN post_tags pt
         ON h.hashtag_id = pt.hashtag_id
GROUP  BY h.hashtag_id, h.hashtag_name
ORDER  BY hashtags_used_counts DESC
LIMIT  10; 
		
        
-- How many unique hashtags have been used?

SELECT Count(DISTINCT h.hashtag_id) AS number_of_unique_hashtag
FROM   hashtags h
JOIN   post_tags pt
ON 	   h.hashtag_id = pt.hashtag_id;


-- Which hashtags are followed by the most users?

SELECT hashtag_id, hashtag_name
FROM   (SELECT h.hashtag_id,
			   h.hashtag_name,
			   Count(hf.user_id) AS hashtags_follows_count,
			   DENSE_RANK() OVER (ORDER BY Count(hf.user_id) DESC) AS hashtags_follows_rank
		FROM   hashtags h
			   JOIN hashtag_follow hf
				 ON h.hashtag_id = hf.hashtag_id
		GROUP  BY h.hashtag_id, h.hashtag_name
		ORDER  BY hashtags_follows_count DESC) t
WHERE  hashtags_follows_rank = 1; 


-- What is the average number of hashtags per post?

SELECT Round(Avg(number_of_hashtags)) AS avg_number_of_hashtags
FROM   (SELECT p.post_id,
               Count(hashtag_id) AS number_of_hashtags
        FROM   post p
               JOIN post_tags pt
                 ON p.post_id = pt.post_id
        GROUP  BY p.post_id) t;
        

-- How many posts have at least one hashtag?

SELECT Count(DISTINCT post_id) AS total_posts_with_hashtags
FROM   (SELECT p.post_id,
               Count(hashtag_id) AS number_of_hashtags
        FROM   post p
               LEFT JOIN post_tags pt
                      ON p.post_id = pt.post_id
        GROUP  BY p.post_id
        HAVING number_of_hashtags >= 1) t; 













        
        
        
        
        
        
        
        
