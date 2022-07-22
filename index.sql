/*  ---S03-L01----------------  Indexes ----------------
can add INDEX when creating a table (can use the keywork KEY instead of INDEX)
 */
USE sample_staff;
DROP TABLE IF EXISTS sample_staff.salary2;
CREATE TABLE salary2 (
	id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(11,2) NOT NULL DEFAULT 0,
    employee_id INT NOT NULL DEFAULT 0,
    INDEX idx_amount (amount),	/* define an index on a single column */
    KEY idx_employee_id (employee_id)	/* or use the keyword KEY */
    );
DESC salary2;
INSERT INTO salary2(amount, employee_id) VALUES (10000,1);
SELECT * FROM salary2;

-- can drop the index after creation
# single line comment can be either -- or #
ALTER TABLE salary2 DROP INDEX idx_amount; 
DESC salary2;
DROP TABLE IF EXISTS sample_staff.salary2;

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
WHERE 1=1department
	AND salary.salary_amount > 150000
    AND from_date >= '1990-01-01'
;
/* result of explain we see the index was used
	id	select_type	table	partitions	type	possible_keys	key	key_len	ref	rows	filtered	Extra
	1	SIMPLE	salary		range	idx_salary_amount	idx_salary_amount	5		179676	33.33	Using index condition; Using where; Using MRR
*/
/* ---S03-L02----------------  Unique Indexes ----------------
Add unique key to department table.
Unique meand no 2 identical keys
*/
ALTER TABLE `department` ADD UNIQUE INDEX `ak_department` (`name`);

# See a unique key in salary table.
# ak_salary consisting of employee_id, from_date, to_date

SELECT *
FROM sample_staff.salary
WHERE 1=1
	AND employee_id = 499998
    AND from_date = '1993-12-27'
    AND to_date = '1994-12-27'
; /* found one row with salary_amount = 40 */

/* MySQL allows to INSERT + UPDATE in one command if there are duplicates 
 In it finds a dupliacte it simply update the fields specified in the UPDATE section
 */
INSERT INTO sample_staff.salary (employee_id, from_date, to_date, insert_dt, insert_process_code)
VALUES
	(499998, '1993-12-27', '1994-12-27', NOW(), 'insert-update')
ON DUPLICATE KEY UPDATE
	sample_staff.salary.salary_amount = salary.salary_amount * 10,
    salary.update_process_code = 'insert-update'
;
-- when we run the select above again and found one row with salary_amount = 400 

/* if there are many fields in the table wnd we want to insert a row with one of the fields changed
	we can use a SELECT to get all the fields*/
INSERT INTO sample_staff.salary #(employee_id, from_date, to_date, insert_dt, insert_process_code)
SELECT * 
	FROM sample_staff.salary AS table2
	WHERE 1=1
		AND employee_id = 499998
		AND from_date = '1993-12-27'
		AND to_date = '1994-12-27'
ON DUPLICATE KEY UPDATE
	salary.salary_amount = salary.salary_amount * 10,
    update_process_code = 'insert-update2'
;

/* ---S03-L03----------------  Composite Indexes ----------------
	in table department_employee_rel there is a composite index consisting of 4 fields
*/
EXPLAIN
SELECT department_employee_rel.* 
FROM sample_staff.department_employee_rel
WHERE 1= 1
	AND department_employee_rel.employee_id IN (10005, 10006, 10007)
    AND department_employee_rel.department_id = 3
	AND `department_employee_rel`.`from_date` = '1989-09-12'
	AND `department_employee_rel`.`to_date` IS NULL
;
/* on query the index is used as long as the sequence of the fields are in order of the index
but if we comment the first field the index is not used
on the other hand, if we drop the 4th firld, the 3 & 4 fields, the 2 to thr 4th fields, the index is used
*/

/* ---S03-L04----------------  Partial Indexes ----------------
	In order to save space n disk we can index on pat of a field (eg. first 4 chars)
    Then in the query we will have to take care of rows that meet the index condition
*/
ALTER TABLE sample_ip.ip_address_varchar20 DROP INDEX idx_ip_address_3chars;

ALTER TABLE sample_ip.ip_address_varchar20 ADD INDEX idx_ip_address_3chars (ip_address(3));
-- Now see the difference in performance - run the queries below.
SELECT *
FROM sample_ip.ip_address_varchar20 
	IGNORE INDEX (idx_ip_address_all_chars)
	IGNORE INDEX (idx_ip_address_7chars)
	IGNORE INDEX (idx_ip_address_3chars)
WHERE 1=1
	AND ip_address_varchar20.ip_address = '123.194.160.219'
; -- took 4.4 seonds
SELECT *
FROM sample_ip.ip_address_varchar20 
--	USE INDEX (idx_ip_address_all_chars)
--	USE INDEX (idx_ip_address_7chars)
	USE INDEX (idx_ip_address_3chars)
WHERE 1=1
	AND ip_address_varchar20.ip_address = '123.194.160.219'
; -- took 2.1 seonds
SELECT *
FROM sample_ip.ip_address_varchar20 
--	USE INDEX (idx_ip_address_all_chars)
	USE INDEX (idx_ip_address_7chars)
--	USE INDEX (idx_ip_address_3chars)
WHERE 1=1
	AND ip_address_varchar20.ip_address = '123.194.160.219'
; -- took 0.12 seonds
SELECT *
FROM sample_ip.ip_address_varchar20 
	USE INDEX (idx_ip_address_all_chars)
--	USE INDEX (idx_ip_address_7chars)
--	USE INDEX (idx_ip_address_3chars)
WHERE 1=1
	AND ip_address_varchar20.ip_address = '123.194.160.219'
; -- took 0.0 seonds
EXPLAIN
SELECT *
FROM sample_ip.ip_address_varchar20 
WHERE 1=1
	AND ip_address_varchar20.ip_address = '123.194.160.219'
; -- took 0.0 seonds

/* ---S03-L05---------------- Index Hןints (USE, IGNORE, FORCE) ----------------
	In the previous section we already saw the Usage of IGNORE and USE
*/
/* ---S03-L06---------------- DO NOT use Functions on indexed columns ----------------
	if you use a function on an index column the index is not used
*/
EXPLAIN
SELECT *
FROM sample_staff.employee
WHERE 1=1
	AND 'ff-975616' = lower(employee.personal_code)
;
/* ---S03-L07---------------- Using two indexes ----------------
	How to use multiple indexes on the same query
*/
-- The employye table has an index on the id (PRIMARY) and an index on the personal_code, named ak_employee
-- when we use both fields in WHERE of a query what happens?
EXPLAIN
SELECT 
	employee.id,
    employee.personal_code
FROM
	sample_staff.employee
WHERE 1=1
	AND (employee.id BETWEEN 12340 AND 12400
		OR
        employee.personal_code = '7C-91159')
; -- found 62 rows in 0 seonds
/* when adding EXPLAIN we see that the engine used a UNOIN of both implicit queries */
SELECT 
	employee.id,
    employee.personal_code
FROM
	sample_staff.employee
WHERE 1=1
	AND employee.id BETWEEN 12340 AND 12400

UNION ALL /* UNION selects DISTINCT but UNION ALL allows for duplicates */

SELECT 
	employee.id,
    employee.personal_code
FROM
	sample_staff.employee
WHERE 1=1
	AND employee.personal_code = '7C-91159'
;
