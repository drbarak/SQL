/*  ---S05-L01----------------  Variables ----------------
	Types of variables:

Global - server system variables @@version
Session - user-defined variables @var
Local - declared in a function or procedure DECLARE var2 INT;
*/
				-- Global
-- Select a version on MySQL
SHOW GLOBAL VARIABLES WHERE variable_name = 'version'; -- MySql version 8.0.29
SELECT @@version;
SHOW GLOBAL VARIABLES; -- 630 variables, many do not have a set value
SHOW GLOBAL VARIABLES WHERE value != '';  -- 579 with set value (the column name taken from the prev query

-- Session variables = user defined
-- Select a user-defined variable
SET @var = 1;
SELECT @var;

	-- Local in a procedure
-- Define a variable inside a stored procedure

DROP PROCEDURE IF EXISTS `sample_staff`.`prc_test`;

DELIMITER //
CREATE PROCEDURE `sample_staff`.`prc_test` (
  in_var INT
)
BEGIN
    DECLARE p_var INT;	-- Here we define the variable p_var
    SET p_var = 1;
    SELECT in_var + p_var;
END;
//
DELIMITER ;

-- Call the stored procedure
CALL prc_test(4);

/*  ---S05-L03----------------  Variables Practice----------------
Create a query to return average salary on 2000-01-01 per department and indication 
	if it's above or below company average at the same date. 
    The result structure should be:
year_month (focus only on 2000-01-01)
department_id
department_name
department_average_salary
company_average_salary
department_vs_company (values: "lower" or "higher" or "same")

Store the company average in a session variable for easier & faster comparison.
*/
SET @focus_date = '2000-01-01';
SET @company_avg = (
	SELECT
		AVG(salary.salary_amount)
    FROM sample_staff.salary
    WHERE 1=1
		AND @focus_date BETWEEN salary.from_date AND IFNULL(salary.to_date, @focus_date)
        AND salary.deleted_flag = 0
	)
;    
SELECT @company_avg;

SELECT EXTRACT(YEAR_MONTH FROM '2009-07-02 01:02:03');

SELECT
	`year_month`,
    department_id,
    department_name,
    department_average_salary,
    company_average_salary,
    IF(department_average_salary > company_average_salary, 'higher',
		IF(department_average_salary < company_average_salary, 'lower', 'same'))
			AS department_vs_company
FROM (
	SELECT 
		(SELECT '2000-01') AS `year_month`,
		department.id AS department_id,
		department.name AS department_name,
		ROUND(AVG(salary.salary_amount), 2) AS department_average_salary,
		ROUND(@company_avg, 2) AS company_average_salary
	FROM sample_staff.salary

	INNER JOIN sample_staff.department_employee_rel ON 1=1
		AND salary.employee_id = department_employee_rel.employee_id
		AND @focus_date BETWEEN department_employee_rel.from_date AND IFNULL(department_employee_rel.to_date, @focus_date)
		AND department_employee_rel.deleted_flag = 0
		
	INNER JOIN sample_staff.department ON 1=1
		AND department.id = department_employee_rel.department_id
 		AND department.deleted_flag = 0
		
	WHERE 1=1
		AND @focus_date BETWEEN salary.from_date AND IFNULL(salary.to_date, @focus_date)
		AND salary.deleted_flag = 0
		
	GROUP BY department.id
	#LIMIT 1
    ) AS q
;

/*
	year_month	department_id	department_name	department_average_salary	company_average_salary	department_vs_company
	2000-01		5				Marketing		62184.03					66589.24				lower
	2000-01	7	Quality Management	83420.15	66589.24	higher
	2000-01	4	Human Resources	62416.01	66589.24	lower
	2000-01	3	Finance	58182.45	66589.24	lower
	2000-01	8	Research	62708.79	66589.24	lower
	2000-01	6	Production	59985.78	66589.24	lower
	2000-01	1	Customer Service	74590.79	66589.24	higher
	2000-01	9	Sales	61006.61	66589.24	lower
	2000-01	2	Development	73368.60	66589.24	higher
*/
    
