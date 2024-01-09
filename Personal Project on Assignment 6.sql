/*
    Name: Celesta Angel Brosowsky
*/

--------------------------------------------------------------------------------
/*				                 Table Creation		  		                  */
--------------------------------------------------------------------------------


CREATE TABLE airbnb(
id BIGINT,
name TEXT,
host_id BIGINT,
host_identity_verified VARCHAR(11),
host_name VARCHAR(50),
neighborhood_group VARCHAR(50),
neighborhood VARCHAR(50),
lat NUMERIC(8,5),
long NUMERIC(8,5),
country VARCHAR(50),
country_code CHAR(2),
instant_bookable VARCHAR(5),
cancellation_policy VARCHAR(20),
room_type VARCHAR(40),
construction_year CHAR(4),
price MONEY,
service_fee MONEY,
minimum_nights INTEGER,
number_of_reviews INTEGER,
last_review DATE,
reviews_per_month NUMERIC(6,4),
review_rate_number INTEGER,
host_listings_count INTEGER,	
availability_365 INTEGER,
house_rules TEXT,
license VARCHAR(10)
);

--------------------------------------------------------------------------------
/*				                 Import Data           		  		          */
--------------------------------------------------------------------------------

COPY airbnb FROM 'C:\Users\Public\Airbnb_Open_Data.csv' DELIMITER ',' CSV HEADER;


--------------------------------------------------------------------------------
/*				                     Create a Backup   		  		          */
--------------------------------------------------------------------------------
CREATE TABLE airbnb_backup AS SELECT *
FROM airbnb;


--------------------------------------------------------------------------------
/*#3 Locate & update values representing missing data in 1 column and perform 1 of the following modifications:

	*/
--------------------------------------------------------------------------------
-- Update rows where country is null and country code is US
UPDATE airbnb
SET country = 'United States'
WHERE country IS NULL AND country_code = 'US';

-- Update rows where country code is null and country is United States
UPDATE airbnb
SET country_code = 'US'
WHERE country_code IS NULL AND country = 'United States';

--Update country and country_code if neighborhood and neighborhood_group were previously identified in that country
UPDATE airbnb AS a1
SET 
  country = (
    SELECT DISTINCT country
    FROM airbnb AS a2
    WHERE a2.neighborhood_group = a1.neighborhood_group
      AND a2.neighborhood = a1.neighborhood
      AND a2.country IS NOT NULL
  ),
  country_code = (
    SELECT DISTINCT country_code
    FROM airbnb AS a3
    WHERE a3.neighborhood_group = a1.neighborhood_group
      AND a3.neighborhood = a1.neighborhood
      AND a3.country_code IS NOT NULL
  )
WHERE
  country IS NULL
  AND country_code IS NULL;


--Update neighborhood_group with misspellings

UPDATE airbnb
SET neighborhood_group = REPLACE(neighborhood_group, 'brookln', 'Brooklyn');

UPDATE airbnb
SET neighborhood_group = REPLACE(neighborhood_group, 'manhatan', 'Manhattan');

-- update minimum_nights to 1 if <1. We had negative values which doesn't make sense
UPDATE airbnb
SET minimum_nights = 1
WHERE minimum_nights <1;

--Drop dulicate rows
CREATE TABLE airbnb_drop_duplicates AS
SELECT DISTINCT * FROM airbnb;
DROP TABLE airbnb;
ALTER TABLE airbnb_drop_duplicates RENAME TO airbnb;

--Delete row with license duplication that was not COMPLETE
DELETE FROM airbnb
WHERE id = 41289964;

-- Dropped column license because it only had 1 value in it
ALTER TABLE airbnb DROP COLUMN license;

--Update number of reviews to 0 where null
UPDATE airbnb
SET number_of_reviews = 0
WHERE number_of_reviews IS NULL;

--Duplicate COLUMN
ALTER TABLE airbnb
ADD column second_host_name VARCHAR(50);
UPDATE airbnb
SET second_host_name = host_name;

--informs us if we have a secondary host (potentially unvetted people)
ALTER TABLE airbnb
ADD COLUMN secondary_host_name boolean;
UPDATE airbnb
SET secondary_host_name = 
	CASE
		WHEN position('&' IN host_name)>0 OR host_name ILIKE '% and %' OR position(',' IN host_name)>0 THEN
		TRUE
		ELSE FALSE
		END;
SELECT host_name, secondary_host_name FROM airbnb
WHERE secondary_host_name = 'true';

--deleting data where the host name and title are null
DELETE FROM airbnb
WHERE host_name IS NULL AND name IS NULL;

--delete repeated airbnbs that have the same lat,long but keeps the one with the most recent id #s
DELETE FROM airbnb a1
USING airbnb a2
WHERE a1.lat = a2.lat
	AND a1.long = a2.long
	AND a1.id < a2.id;

-- tried to make sure all host id's were confirmed. They were

SELECT host_id, COUNT(*) AS occurrence_count,
       MIN(host_identity_verified) AS min_verified,
       MAX(host_identity_verified) AS max_verified
FROM airbnb
GROUP BY host_id
HAVING COUNT(*) > 1 AND MIN(host_identity_verified) <> MAX(host_identity_verified)
ORDER BY host_id;