CREATE SCHEMA `CJMS`;
USE `CJMS`;
DROP SCHEMA `CJMS`;

CREATE TABLE planets(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(30) NOT NULL
);

CREATE TABLE spaceports(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(50) NOT NULL,
planet_id INT(11),

CONSTRAINT FOREIGN KEY fk_spaceports_planets (planet_id)
	REFERENCES planets(id)
);

CREATE TABLE spaceships(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(50) NOT NULL,
manufacturer VARCHAR(30) NOT NULL,
light_speed_rate INT(11) default 0
);

CREATE TABLE journeys(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
journey_start DATETIME NOT NULL,
journey_end DATETIME NOT NULL,
purpose ENUM('Medical', 'Technical', 'Educational', 'Military') NOT NULL,
destination_spaceport_id INT(11),
spaceship_id INT(11),

CONSTRAINT FOREIGN KEY fk_journeys_spaceports (destination_spaceport_id)
	REFERENCES spaceports(id),
    
CONSTRAINT FOREIGN KEY fk_journeys_spaceships (spaceship_id)
	REFERENCES spaceships(id)
);

CREATE TABLE colonists(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(20) NOT NULL,
last_name VARCHAR(20) NOT NULL,
ucn char(10) UNIQUE NOT NULL,
birth_date DATE NOT NULL
);

CREATE TABLE travel_cards(
id INT(11) PRIMARY KEY AUTO_INCREMENT,
card_number CHAR(10) UNIQUE NOT NULL,
job_during_journey ENUM('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook') NOT NULL,
colonist_id INT(11),
journey_id INT(11),

CONSTRAINT FOREIGN KEY fk_travel_cards_colonists (colonist_id)
	REFERENCES colonists(id),
    
CONSTRAINT FOREIGN KEY fk_travel_cards_journeys (journey_id)
	REFERENCES journeys(id)
);

-- 01. Data Insertion

INSERT INTO `travel_cards`(
	card_number,
    job_during_journey,
	colonist_id,
    journey_id
)
SELECT 
	(
	CASE
		WHEN birth_date > '1980-01-01' THEN
			CONCAT_WS('', YEAR(birth_date), DAY(birth_date), LEFT(ucn, 4))
		ELSE CONCAT_WS('',YEAR(birth_date), MONTH(birth_date), RIGHT(ucn, 4))
        END
    ) AS card_number,
    (
    CASE
		WHEN id % 2 = 0 THEN  'Pilot'
		WHEN id % 3 = 0 THEN  'Cook'
        ELSE  'Engineer'
    END
    ) AS job_during_journey,
    id AS colonist_id,
    LEFT(ucn, 1) AS journey_id
    FROM `colonists`
    WHERE id BETWEEN 96 AND 100;

-- 02. Data Update

UPDATE `journeys`
	SET purpose = (
		CASE
			WHEN id % 2 = 0 THEN 'Medical'
			WHEN id % 3 = 0 THEN 'Technical'
			WHEN id % 5 = 0 THEN 'Educational'
			WHEN id % 7 = 0 THEN 'Military'
            ELSE purpose
        END 
);

-- 03. Data Delete

DELETE  `colonists`
FROM  `colonists` 
		LEFT JOIN
	`travel_cards` ON colonists.id = travel_cards.colonist_id
WHERE travel_cards.colonist_id IS NULL;


-- 04.Section: Querying – 100 pts
-- 04.Extract all travel cards

SELCT 
	t.card_number,
	t.job_during_journey
FROM
	`travel_cards` AS t
ORDER BY t.card_number;


-- 05. Extract all colonists

SELECT 
	c.id,
	CONCAT_WS(' ', c.first_name, c.last_name) AS full_name,
	c.ucn
FROM
	`colonists` AS c
ORDER BY c.first_name, c.last_name, c.id;

-- 06. Extract all military journeys

SELECT 
	j.id,
	j.journey_start,
	j.journey_end
FROM
	`journeys` AS j
WHERE j.purpose LIKE 'Military'
ORDER BY j.journey_start;


-- 07. Extract all pilots
	
SELECT 
	c.id,
	CONCAT_WS(' ', c.first_name, c.last_name) AS full_name
FROM
	colonists as c
		JOIN
	travel_cards AS t ON c.id = t.colonist_id
WHERE t.job_during_journey LIKE 'Pilot'
ORDER BY c.id;


-- 08. Count all colonists that are on technical journey

SELECT 
	count(c.id)
FROM
	`colonists`AS c
		JOIN
	`travel_cards` AS t ON c.id = t.colonist_id
		JOIN
	`journeys` AS j ON t.journey_id = j.id
WHERE j.purpose LIKE 'Technical';


-- 09.Extract the fastest spaceship

SELECT 
	s.name AS spaceship_name,
    sp.name AS spaceport_name
FROM
	`spaceships` AS s
		JOIN
	`journeys` AS j ON s.id = j.spaceship_id
		JOIN
	`spaceports` AS sp ON j.destination_spaceport_id = sp.id
ORDER BY s.light_speed_rate DESC
LIMIT 1;


-- 10.Extract spaceships with pilots younger than 30 years

SELECT 
	s.name AS name,
    s.manufacturer
FROM
	`spaceships` AS s
		JOIN
	`journeys` AS j ON s.id = j.spaceship_id
		JOIN
	`travel_cards` AS t ON j.id = t.journey_id
		JOIN
	`colonists` as c ON t.colonist_id = c.id
WHERE (t.job_during_journey LIKE 'Pilot')
		AND YEAR('2019-01-01') - YEAR(c.birth_date) < 30
ORDER BY s.name;


-- 11. Extract all educational mission planets and spaceports

SELECT 
	p.name AS planet_name,
    sp.name AS spaceport_name
FROM
	`planets` AS p
		JOIN
	`spaceports` AS sp ON p.id = sp.planet_id
		JOIN	
	`journeys` AS j ON sp.id = j.destination_spaceport_id
WHERE j.purpose LIKE 'Educational'
ORDER BY sp.name DESC;


-- 12. Extract all planets and their journey count

SELECT 
	p.name AS planet_name,
    COUNT(j.id) AS journeys_count
FROM
	`planets` AS p
		JOIN
	`spaceports` AS sp ON p.id = sp.planet_id
		JOIN	
	`journeys` AS j ON sp.id = j.destination_spaceport_id
GROUP BY p.name
ORDER BY journeys_count DESC, p.name;


-- 13.Extract the shortest journey
-- Extract from the database the shortest journey, its destination spaceport name, planet name and purpose.

SELECT 
	j.id,
	p.name AS planet_name,
    sp.name AS spaceport_name,
    j.purpose AS journey_purpose
FROM
	`planets` AS p
		JOIN
	`spaceports` AS sp ON p.id = sp.planet_id
		JOIN	
	`journeys` AS j ON sp.id = j.destination_spaceport_id
ORDER BY DATE(j.journey_end) - DATE(j.journey_start)
LIMIT 1;


-- 14.Extract the less popular job
-- Extract from the database the less popular job in the longest journey. 
-- In other words, the job with less assign colonists.

SELECT 
	t.job_during_journey AS job_name
FROM
	`travel_cards` AS t
		JOIN
	`colonists` AS c ON t.colonist_id = c.id
		JOIN	
	`journeys` AS j ON t.journey_id = j.id
ORDER BY DATEDIFF(j.journey_end, j.journey_start) DESC
LIMIT 1;

-- another way
SELECT 
	t.job_during_journey AS job_name
FROM
	`travel_cards` AS t
WHERE t.journey_id = (
	SELECT j.id FROM `journeys` AS j
    ORDER BY DATEDIFF(j.journey_end, j.journey_start) DESC
    LIMIT 1
)
GROUP BY job_name
LIMIT 1;


-- 5. Section: Programmability – 30 pts
 
-- 15. Get colonists count
-- Create a user defined function with the name udf_count_colonists_by_destination_planet (planet_name VARCHAR (30)) 
-- that receives planet name and returns the count of all colonists sent to that planet.


/*  Example:
SELECT p.name, udf_count_colonists_by_destination_planet(‘Otroyphus’) AS count
FROM planets AS p
WHERE p.name = ‘Otroyphus’;

 Expected:      
	name           count
    Otroyphus       35     */
    

DELIMITER //
CREATE FUNCTION udf_count_colonists_by_destination_planet (planet_name VARCHAR (30))
RETURNS INT(30)
DETERMINISTIC
BEGIN
	DECLARE result INT;
    
    SELECT 
		count(c.id) INTO result
	FROM
		`travel_cards` AS t
			JOIN
		`colonists` AS c ON t.colonist_id = c.id
			JOIN
		`journeys` AS j ON t.journey_id = j.id
			JOIN
		`spaceports` AS sp ON j.destination_spaceport_id = sp.id
			JOIN
		`planets` AS p ON sp.planet_id = p.id
	WHERE p.name LIKE planet_name;

	RETURN result;
END
//
DELIMITER ;

SELECT  udf_count_colonists_by_destination_planet('Otroyphus');
DROP FUNCTION udf_count_colonists_by_destination_planet;


-- 16. Modify spaceship

/*Create a user defined stored procedure with the name udp_modify_spaceship_light_speed_rate(spaceship_name VARCHAR(50), 
	light_speed_rate_increse INT(11)) that receives a spaceship name and light speed increase value and increases spaceship light speed only if the given spaceship exists.
	If the modifying is not successful rollback any changes and throw an exception with error code ‘45000’ and message: 
    “Spaceship you are trying to modify does not exists.”*/

DELIMITER // 
CREATE PROCEDURE udp_modify_spaceship_light_speed_rate(
spaceship_name VARCHAR(50),
light_speed_rate_increse INT(11))
BEGIN
	DECLARE spaceship_name_in_db VARCHAR(30);
    
	SET spaceship_name_in_db := (
		 SELECT s.name FROM `spaceships` AS s WHERE s.name LIKE spaceship_name);
        
	START TRANSACTION;
		IF 
			spaceship_name_in_db IS NULL
			THEN 
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Spaceship you are trying to modify does not exists.';
			ROLLBACK;
		ELSE 
			UPDATE `spaceships` AS s
			SET s.light_speed_rate = s.light_speed_rate + light_speed_rate_increse
            WHERE name = spaceship_name_in_db;
	COMMIT;
		END IF;
END
//
DELIMITER ;

SET sql_safe_updates=0;

CALL udp_modify_spaceship_light_speed_rate ('Na Pesho koraba', 1914);
SELECT name, light_speed_rate FROM `spaceships` WHERE name = 'Na Pesho koraba';
-- Expected response: Spaceship you are trying to modify does not exists.

CALL udp_modify_spaceship_light_speed_rate ('USS Templar', 5);
SELECT name, light_speed_rate FROM `spaceships` WHERE name = 'USS Templar';
-- Expected: USS Templar     11

DROP PROCEDURE udp_modify_spaceship_light_speed_rate;







