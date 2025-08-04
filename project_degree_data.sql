-- CREATING SCHEMA AND IMPORTING DATA THROUGH TABLE DATA IMPORT WIZARD --

CREATE SCHEMA project_degrees_data;

-- CREATING STAGING TABLES TO KEEP THE RAW DATA UNTOUCHED --
-- STANDARDIZING THE COLUMN NAMES TO MAKE MY LIFE EASIER --

CREATE TABLE `employee_data_staging` (
  `employee_id` text,
  `first_name` text,
  `last_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `business_travel` text,
  `department` text,
  `distance_from_home` int DEFAULT NULL,
  `state` text,
  `ethnicity` text,
  `education` int DEFAULT NULL,
  `education_field` text,
  `job_role` text,
  `marital_status` text,
  `salary` int DEFAULT NULL,
  `stock_option_level` int DEFAULT NULL,
  `over_time` text,
  `hire_date` text,
  `attrition` text,
  `years_at_company` int DEFAULT NULL,
  `years_in_most_recent_role` int DEFAULT NULL,
  `years_since_last_promotion` int DEFAULT NULL,
  `years_with_curr_manager` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `performance_data_staging` (
  `performance_id` text,
  `employee_id` text,
  `review_date` text,
  `environment_satisfaction` int DEFAULT NULL,
  `job_satisfaction` int DEFAULT NULL,
  `relationship_satisfaction` int DEFAULT NULL,
  `training_opportunities_within_year` int DEFAULT NULL,
  `training_opportunities_taken` int DEFAULT NULL,
  `work_life_balance` int DEFAULT NULL,
  `self_rating` int DEFAULT NULL,
  `manager_rating` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO employee_data_staging
SELECT *
FROM employee_data;

INSERT INTO performance_data_staging
SELECT *
FROM performance_data;

-- CHECKING HOW THE EMPLOYEE IDs MATCH --

SELECT e.employee_id, p.employee_id
FROM employee_data_staging AS e
	JOIN performance_data_staging AS p
    ON e.employee_id = p.employee_id;
    
-- RETURNED MORE ROWS THAN EXPECTED, CHECKING FOR DUPLICATES --

SELECT employee_id, COUNT(1) as cnt
FROM performance_data_staging
GROUP BY employee_id
;

SELECT employee_id, COUNT(1) as cnt
FROM employee_data_staging
GROUP BY employee_id
ORDER BY 2 DESC;

SELECT *
FROM performance_data_staging
WHERE employee_id = '79F7-78EC'
;

-- REALIZED THAT THE PERFORMANCE_DATA CONTAINS PERFORMANCE RATING OF THE EMPLOYEES OVER THE YEARS --

SELECT employee_id, AVG(manager_rating)
FROM performance_data_staging
GROUP BY employee_id
;

SELECT employee_id, AVG(self_rating)
FROM performance_data_staging
GROUP BY employee_id;

-- CREATING A TABLE THAT HAS ONLY THE DISTINCT EMPLOYEE IDs. IN THE NEXT STEP WE WILL GET THE AVERAGE FROM THE PERFORMANCE_DATA_STAGING --

SELECT *, row_number() OVER (PARTITION BY employee_id)
FROM performance_data_staging
;

CREATE TABLE `performance_data_staging2` (
  `performance_id` text,
  `employee_id` text,
  `review_date` text,
  `environment_satisfaction` int DEFAULT NULL,
  `job_satisfaction` int DEFAULT NULL,
  `relationship_satisfaction` int DEFAULT NULL,
  `training_opportunities_within_year` int DEFAULT NULL,
  `training_opportunities_taken` int DEFAULT NULL,
  `work_life_balance` int DEFAULT NULL,
  `self_rating` int DEFAULT NULL,
  `manager_rating` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO performance_data_staging2
SELECT *, row_number() OVER (PARTITION BY employee_id)
FROM performance_data_staging;

SELECT *
FROM performance_data_staging2
WHERE row_num > 1;

DELETE
FROM performance_data_staging2
WHERE row_num > 1;

-- GETING THE AVERAGE RATINGS HERE --

CREATE TABLE `average_self_rating` (
  `employee_id` text,
  `ave_self_rating` DECIMAL(5,4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO average_self_rating
SELECT employee_id, AVG(self_rating)
FROM performance_data_staging
GROUP BY employee_id;

CREATE TABLE `average_manager_rating` (
  `employee_id` text,
  `ave_manager_rating` DECIMAL(5,4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO average_manager_rating
SELECT employee_id, AVG(manager_rating)
FROM performance_data_staging
GROUP BY employee_id;

CREATE TABLE `performance_data_staging3` (
  `performance_id` text,
  `employee_id` text,
  `review_date` text,
  `environment_satisfaction` int DEFAULT NULL,
  `job_satisfaction` int DEFAULT NULL,
  `relationship_satisfaction` int DEFAULT NULL,
  `training_opportunities_within_year` int DEFAULT NULL,
  `training_opportunities_taken` int DEFAULT NULL,
  `work_life_balance` int DEFAULT NULL,
  `self_rating` int DEFAULT NULL,
  `manager_rating` int DEFAULT NULL,
  `row_num` int DEFAULT NULL,
  `average_self_rating` DECIMAL(5,4),
  `average_manager_rating` DECIMAL(5,4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO performance_data_staging3
SELECT a.performance_id, a.employee_id, a.review_date, a.environment_satisfaction, a.job_satisfaction, a.relationship_satisfaction, a.training_opportunities_within_year, a. training_opportunities_taken,
a.work_life_balance, a.self_rating, a.manager_rating, a.row_num, b.ave_self_rating, c.ave_manager_rating
FROM performance_data_staging2 AS a
	JOIN average_self_rating AS b ON a.employee_id = b.employee_id
    JOIN average_manager_rating AS c ON a.employee_id = c.employee_id;

SELECT *
FROM performance_data_staging3;

SELECT *
FROM performance_data_staging
WHERE employee_id = 'F93E-BDEF';

SELECT *
FROM performance_data_staging3
WHERE employee_id = 'F93E-BDEF';

SELECT a.self_rating, a.manager_rating, average_self_rating, average_manager_rating
FROM performance_data_staging2 AS a
	JOIN performance_data_staging3 AS b
    ON a.employee_id = b.employee_id ;

SELECT *
FROM performance_data_staging3;

-- CREATING A DIFFERENT TABLE TO CATEGORIZE THE RATINGS. WE WILL ROUND OFF THE AVERAGE RATINGS --
-- 4.5 - 5 = EXCELLENT; 3.5 - 4.49 = ABOVE AVERAGE, 2.5 - 3.49 = AVERAGE, 1.5 - 2.49 = BELOW AVERAGE, 0 - 1.49 = POOR --

SELECT average_self_rating, average_manager_rating, 
CASE 
WHEN average_self_rating >= 4.5 THEN 'EXCELLENT'
WHEN average_self_rating >= 3.5 THEN 'ABOVE AVERAGE'
WHEN average_self_rating >= 2.5 THEN 'AVERAGE'
WHEN average_self_rating >= 1.5 THEN 'BELOW AVERAGE'
WHEN average_self_rating < 1.5 THEN 'POOR' END AS self_rating_category,
CASE 
WHEN average_manager_rating >= 4.5 THEN 'EXCELLENT'
WHEN average_manager_rating >= 3.5 THEN 'ABOVE AVERAGE'
WHEN average_manager_rating >= 2.5 THEN 'AVERAGE'
WHEN average_manager_rating >= 1.5 THEN 'BELOW AVERAGE'
WHEN average_manager_rating < 1.5 THEN 'POOR' END AS manager_rating_category
FROM performance_data_staging3;

CREATE TABLE `performance_data_staging4` (
  `performance_id` text,
  `employee_id` text,
  `review_date` text,
  `environment_satisfaction` int DEFAULT NULL,
  `job_satisfaction` int DEFAULT NULL,
  `relationship_satisfaction` int DEFAULT NULL,
  `training_opportunities_within_year` int DEFAULT NULL,
  `training_opportunities_taken` int DEFAULT NULL,
  `work_life_balance` int DEFAULT NULL,
  `self_rating` int DEFAULT NULL,
  `manager_rating` int DEFAULT NULL,
  `row_num` int DEFAULT NULL,
  `average_self_rating` decimal(5,4) DEFAULT NULL,
  `average_manager_rating` decimal(5,4) DEFAULT NULL,
  `self_rating_category` varchar(50),
  `manager_rating_category` varchar(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO performance_data_staging4
SELECT *, CASE 
WHEN average_self_rating >= 4.5 THEN 'Excellent'
WHEN average_self_rating >= 3.5 THEN 'Above Average'
WHEN average_self_rating >= 2.5 THEN 'Average'
WHEN average_self_rating >= 1.5 THEN 'Below Average'
WHEN average_self_rating < 1.5 THEN 'Poor' END AS self_rating_category,
CASE 
WHEN average_manager_rating >= 4.5 THEN 'Excellent'
WHEN average_manager_rating >= 3.5 THEN 'Above Average'
WHEN average_manager_rating >= 2.5 THEN 'Average'
WHEN average_manager_rating >= 1.5 THEN 'Below Average'
WHEN average_manager_rating < 1.5 THEN 'Poor' END AS manager_rating_category
FROM performance_data_staging3;

SELECT *
FROM performance_data_staging4;

-- ASSIGNING VALUES TO EDUCATION LEVEL --

SELECT *,
CASE
WHEN education = 5 THEN 'PhD'
WHEN education = 4 THEN "Master's Degree"
WHEN education = 3 THEN "Bachelor's Degree"
WHEN education = 2 THEN 'High School'
WHEN education = 1 THEN 'No Formal Qualifications' END AS 'Education Level'
FROM employee_data_staging;

CREATE TABLE `employee_data_staging2` (
  `employee_id` text,
  `first_name` text,
  `last_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `business_travel` text,
  `department` text,
  `distance_from_home` int DEFAULT NULL,
  `state` text,
  `ethnicity` text,
  `education` int DEFAULT NULL,
  `education_field` text,
  `job_role` text,
  `marital_status` text,
  `salary` int DEFAULT NULL,
  `stock_option_level` int DEFAULT NULL,
  `over_time` text,
  `hire_date` text,
  `attrition` text,
  `years_at_company` int DEFAULT NULL,
  `years_in_most_recent_role` int DEFAULT NULL,
  `years_since_last_promotion` int DEFAULT NULL,
  `years_with_curr_manager` int DEFAULT NULL,
  `education_level` varchar(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO employee_data_staging2
SELECT *,
CASE
WHEN education = 5 THEN 'PhD'
WHEN education = 4 THEN "Master's Degree"
WHEN education = 3 THEN "Bachelor's Degree"
WHEN education = 2 THEN 'High School'
WHEN education = 1 THEN 'No Formal Qualifications' END AS 'Education Level'
FROM employee_data_staging;

SELECT *
FROM employee_data_staging2;

-- CONCATINATING first_name AND last_name --

SELECT CONCAT(first_name, ' ', last_name) AS employee_name
FROM employee_data_staging2;

CREATE TABLE `employee_data_staging3` (
  `employee_id` text,
  `first_name` text,
  `last_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `business_travel` text,
  `department` text,
  `distance_from_home` int DEFAULT NULL,
  `state` text,
  `ethnicity` text,
  `education` int DEFAULT NULL,
  `education_field` text,
  `job_role` text,
  `marital_status` text,
  `salary` int DEFAULT NULL,
  `stock_option_level` int DEFAULT NULL,
  `over_time` text,
  `hire_date` text,
  `attrition` text,
  `years_at_company` int DEFAULT NULL,
  `years_in_most_recent_role` int DEFAULT NULL,
  `years_since_last_promotion` int DEFAULT NULL,
  `years_with_curr_manager` int DEFAULT NULL,
  `education_level` varchar(50) DEFAULT NULL,
  `employee_name` varchar(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO employee_data_staging3
SELECT *, CONCAT(first_name, ' ', last_name) AS employee_name
FROM employee_data_staging2;

-- CHECKING HOW THE FINAL TABLES MATCH --

SELECT e.employee_id, p.employee_id
FROM employee_data_staging3 AS e
	JOIN performance_data_staging4 AS p
    ON e.employee_id = p.employee_id;

-- CREATING A COMBINED TABLE THAT ONLY HAS THE RELEVANT INFORMATIONS --
-- WE WILL ALSO ADD AN EDUCATION_LEVEL_SORTER IN THIS ORDER: PhD = 1, Master's Degree - 2, Bachelor's Degree - 3, High School - 4, No Formal Qualifications = 5 --

SELECT education_level, CASE
WHEN education_level = 'PhD' THEN 1
WHEN education_level = "Master's Degree" THEN 2
WHEN education_level = "Bachelor's Degree" THEN 3
WHEN education_level = 'High School' THEN 4
WHEN education_level = 'No Formal Qualifications' THEN 5 END AS education_level_sorter
FROM employee_data_staging3;

CREATE TABLE `employee_performance_data` (
  `employee_id` VARCHAR(50),
  `employee_name` VARCHAR(100),
  `education_level` VARCHAR(50),
  `education_field` VARCHAR(50),
  `department` VARCHAR(50),
  `job_role` VARCHAR(50),
  `self_rating` DECIMAL(5,4),
  `self_rating_category` VARCHAR(50),
  `manager_rating` DECIMAL (5,4),
  `manager_rating_category` VARCHAR(50),
  `salary` int,
  `marital_status` VARCHAR(50),
  `ethnicity` VARCHAR(50),
  `gender` VARCHAR(50),
  `age` int,
  `years_at_company` int,
  `training_opportunities_taken` int,
  `education_level_sorter` int
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO employee_performance_data
SELECT e.employee_id, e.employee_name, e.education_level, e.education_field, e.department, e.job_role, p.average_self_rating, p.self_rating_category, p.average_manager_rating, p.manager_rating_category,
e.salary, e.marital_status, e.ethnicity, e.gender, e.age, e.years_at_company, p.training_opportunities_taken, CASE
WHEN education_level = 'PhD' THEN 1
WHEN education_level = "Master's Degree" THEN 2
WHEN education_level = "Bachelor's Degree" THEN 3
WHEN education_level = 'High School' THEN 4
WHEN education_level = 'No Formal Qualifications' THEN 5 END AS education_level_sorter
FROM employee_data_staging3 AS e
	JOIN performance_data_staging4 AS p
    ON e.employee_id = p.employee_id;

-- FINAL CLEANING --
-- STANDARDIZING --

UPDATE employee_performance_data
SET education_field = TRIM('Marketing')
WHERE education_field LIKE '%Marketing%';

-- FINAL TABLE --

SELECT *
FROM employee_performance_data;


