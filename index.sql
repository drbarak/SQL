/* can add INDEX when creating a table (can use the keywork KEY instead of INDEX) */
USE sample_staff;
CREATE TABLE salary2 (
	id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(11,2) NOT NULL DEFAULT 0,
    employee_id INT NOT NULL DEFAULT 0,
    INDEX idx_amount (amount)
    );
DESC salary2;
INSERT INTO salary2(amount, employee_id) VALUES (10000,1);
SELECT * FROM salary2;


-- can drop the index after creation
# single line comment can be either -- or #
ALTER TABLE salary2 DROP INDEX idx_amount; 
DESC salary2;

SHOW INDEXES FROM salary;
ALTER TABLE salary DROP INDEX idx_salary_amount;
SHOW INDEXES FROM salary;

-- Select without an index takes 4+ seconds
SELECT *
FROM sample_staff.salary
WHERE 1=1
	AND salary.salary_amount > 150000
    AND from_date >= '1990-01-01'
;
-- Explain select (Add "EXPLAIN" before the query)
-- shows that it was 'Using Where'
EXPLAIN
SELECT *
FROM sample_staff.salary
WHERE 1=1
	AND salary.salary_amount > 150000
    AND from_date >= '1990-01-01'
;
/*
	id	select_type	table	partitions	type	possible_keys	key	key_len	ref	rows	filtered	Extra
	1	SIMPLE	salary		ALL					2730400	11.11	Using where
*/
-- now add back the index
ALTER TABLE sample_staff.salary ADD INDEX idx_salary_amount (salary_amount);
SHOW INDEXES FROM sample_staff.salary;
-- now repeat the query - took 0 seconds
#EXPLAIN
SELECT *
FROM sample_staff.salary
WHERE 1=1
	AND salary.salary_amount > 150000
    AND from_date >= '1990-01-01'
;
/* result of explain we see the index was used
	id	select_type	table	partitions	type	possible_keys	key	key_len	ref	rows	filtered	Extra
	1	SIMPLE	salary		range	idx_salary_amount	idx_salary_amount	5		179676	33.33	Using index condition; Using where; Using MRR
*/
