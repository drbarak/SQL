/*  ---S06-L01----------------  Analytic functions -----------------
MySQL
	in 5.7 hmmm... not many, but we can learn to simulate them (yay!)
    But they do exists in 8.0 - still simulating then will deepen the understaning
	See User-defined functions in C/C++ to enhance MySQL
PostgreSQL & MySQL 8.0
	ROW_NUMBER()
	RANK(), DENSE_RANK()
	LAG(), `LEAD()``
	FIRST_VALUE(), LAST_VALUE(), NTH_VALUE()
    
-- in PostgreSQL    
SELECT
  letter,
  ROW_NUMBER() OVER(ORDER BY letter),
  RANK()       OVER(ORDER BY letter),
  DENSE_RANK() OVER(ORDER BY letter),
  PERCENT_RANK() OVER(ORDER BY letter),
  NTILE(10) OVER(ORDER BY letter),
  FIRST_VALUE(letter) OVER(),
  LAST_VALUE(letter) OVER(),
  NTH_VALUE(letter, 3) OVER(ORDER BY letter),
  LAG(letter) OVER(),
  LEAD(letter) OVER()
FROM sample.test
ORDER BY letter
;    
*/

/*  ---S06-L02----------------  Analytic function: ROW NUMBER ----------------- */
SELECT 
	ROW_NUMBER() OVER (
		ORDER BY department.name
	) row_num,
    department.name,
    department.id
FROM 
	sample_staff.department
ORDER BY 
	department.name
; -- using MYsql 8.0
/*+---------+--------------------+----+
| row_num |        name        | id |
+=========+====================+====+
| 1       | Customer Service   | 1  |
| 2       | Development        | 2  |
| 3       | Finance            | 3  |
| 4       | Human Resources    | 4  |
| 5       | Marketing          | 5  |
| 6       | Production         | 6  |
| 7       | Quality Management | 7  |
| 8       | Research           | 8  |
| 9       | Sales              | 9  |
+---------+--------------------+----+
*/
CREATE TABLE sample_staff.sample_window (
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    letter CHAR)
;
INSERT INTO sample_staff.sample_window(letter) VALUES ('a'),('a'),('a'),('b'),('c'),('c'),('d'),('e')
;
SELECT *
FROM sample_staff.sample_window;
/*+----+--------+
| id | letter |
+----+--------+
| 1  | a      |
| 2  | a      |
| 3  | a      |
| 4  | b      |
| 5  | c      |
| 6  | c      |
| 7  | d      |
| 8  | e      |
+----+--------+*/
SET @row_number := 0;
SELECT 
	id,
    letter,
    @row_number := IFNULL(@row_number, 0) + 1 AS `row_number`
FROM sample_staff.sample_window;
;
/* problem: each time running the query without the SET the row number increases
to prevent it we need to insert it as part of the query
but to avoid it being a separate column we have to use a subquery */
SELECT 
	id,
    letter,
    @row_number := @row_number + 1 AS `row_number`
FROM 
	(SELECT @row_number := 0) as q,
	sample_staff.sample_window
;
/*+----+--------+------------+
| id | letter | row_number |
+----+--------+------------+
| 1  | a      | 1          |
| 2  | a      | 2          |
| 3  | a      | 3          |
| 4  | b      | 4          |
| 5  | c      | 5          |
| 6  | c      | 6          |
| 7  | d      | 7          |
| 8  | e      | 8          |
+----+--------+------------+
Below same query in MySQL 8.0 usingthe ROW_NUMBER anality function
*/
SELECT 
    sample_window.id AS id,
    sample_window.letter AS letter,
	ROW_NUMBER() OVER (
		ORDER BY sample_window.id
	) row_num    
FROM 
	sample_staff.sample_window
; -- using MYsql 8.0 
/* 
Tיhe above query orders the row_number based on the primary key = id.
If we want it to be in DESC order we just need to add ORDER BY id DESC
*/ 
SELECT 
	sample_window.id AS id,
    sample_window.letter AS letter,
    @row_number := @row_number + 1 AS `row_number`
FROM 
	(SELECT @row_number := 0) as q,
	sample_staff.sample_window
ORDER BY sample_window.id DESC
; -- but this reverse the order of the id, and we want just to reverse th order of the row_number such that it goes from 8 to 1
SELECT 
    sample_window.id AS id,
    sample_window.letter AS letter,
	ROW_NUMBER() OVER (
		ORDER BY sample_window.id DESC
	) row_num    
FROM 
	sample_staff.sample_window
ORDER BY 
	sample_window.id    
; -- using MYsql 8.0 
SELECT
	id,
    letter,
    `row_number`
FROM (
	SELECT 
		sample_window.id AS id,
		sample_window.letter AS letter,
		@row_number := @row_number + 1 AS `row_number`
	FROM 
		(SELECT @row_number := 0) as q,
		sample_staff.sample_window
	ORDER BY sample_window.id DESC
	) AS q
ORDER BY id
; -- using MYsql 5.7
/*+----+--------+------------+
| id | letter | row_number |
| 1  | a      | 8          |
| 2  | a      | 7          |
| 3  | a      | 6          |
| 4  | b      | 5          |
| 5  | c      | 4          |
| 6  | c      | 3          |
| 7  | d      | 2          |
| 8  | e      | 1          |
+----+--------+------------+*/
/* now we wnat row number based on letter DESC and id ASC */
SELECT 
    sample_window.id AS id,
    sample_window.letter AS letter,
	ROW_NUMBER() OVER (
		ORDER BY sample_window.letter DESC, sample_window.id ASC
	) row_num    
FROM 
	sample_staff.sample_window
ORDER BY 
	letter,
	id    
; -- using MYsql 8.0 
SELECT
	id,
    letter,
    `row_number`
FROM (
	SELECT 
		sample_window.id AS id,
		sample_window.letter AS letter,
		@row_number := @row_number + 1 AS `row_number`
	FROM 
		(SELECT @row_number := 0) as q,
		sample_staff.sample_window
	ORDER BY 
		sample_window.letter DESC,
		sample_window.id 
	) AS q
ORDER BY 
	letter,
	id    
; -- using MYsql 5.7
/*+----+--------+------------+
| id | letter | row_number |
+----+--------+------------+
| 1  | a      | 6          |
| 2  | a      | 7          |
| 3  | a      | 8          |
| 4  | b      | 5          |
| 5  | c      | 3          |
| 6  | c      | 4          |
| 7  | d      | 2          |
| 8  | e      | 1          |
+----+--------+------------+*/

/* --- RANK() ----------
behaves like ROW_NUMBER(), except that “equal” rows are ranked the same.
*/
SELECT 
    sample_window.id AS id,
    sample_window.letter AS letter,
    RANK() OVER (
		-- PARTITION BY sample_window.letter
		ORDER BY sample_window.letter
	) AS `rank`
FROM 
	sample_staff.sample_window
ORDER BY 
	letter,
	id    
; -- using MYsql 8.0
/*+----+--------+------+
| id | letter | rank |
+----+--------+------+
| 1  | a      | 1    |
| 2  | a      | 1    |
| 3  | a      | 1    |
| 4  | b      | 4    |
| 5  | c      | 5    |
| 6  | c      | 5    |
| 7  | d      | 7    |
| 8  | e      | 8    |
+----+--------+------+*/
SELECT
	id,
    letter,
    #`row_number`,
    `rank`
FROM (
	SELECT 
		sample_window.id AS id,
		sample_window.letter AS letter,
		@row_number := @row_number + 1 AS `row_number`,
        IF(@prev IS NULL, @prev := sample_window.letter, IF(@prev != sample_window.letter, @rank := @row_number, @prev)),
        IF(@prev != sample_window.letter, @prev := sample_window.letter, @prev),
        @rank AS `rank`
	FROM 
		(SELECT @row_number := 0, @rank := 1, @prev := NULL) as q,
		sample_staff.sample_window
	ORDER BY 
		sample_window.letter,
		sample_window.id 
	) AS q
ORDER BY 
	id,
    letter
; -- using MYsql 5.7

/* --- DENSE_RANK() ----------
	DENSE_RANK() is a rank with no gaps
*/
SELECT 
    sample_window.id AS id,
    sample_window.letter AS letter,
    DENSE_RANK() OVER (
		-- PARTITION BY sample_window.letter
		ORDER BY sample_window.letter
	) AS `rank`
FROM 
	sample_staff.sample_window
ORDER BY 
	letter,
	id    
; -- using MYsql 8.0
/*+----+--------+------+
| id | letter | rank |
+----+--------+------+
| 1  | a      | 1    |
+----+--------+------+
| 2  | a      | 1    |
| 3  | a      | 1    |
| 4  | b      | 2    |
| 5  | c      | 3    |
| 6  | c      | 3    |
| 7  | d      | 4    |
| 8  | e      | 5    |
+----+--------+------+*/
SELECT
	id,
    letter,
    #`row_number`,
    `rank`
FROM (
	SELECT 
		sample_window.id AS id,
		sample_window.letter AS letter,
		#@row_number := @row_number + 1 AS `row_number`,
        IF(@prev IS NULL, @prev := sample_window.letter, IF(@prev != sample_window.letter, @rank := @rank + 1, @prev)),
        IF(@prev != sample_window.letter, @prev := sample_window.letter, @prev),
        @rank AS `rank`
	FROM 
		(SELECT @row_number := 0, @rank := 1, @prev := NULL) as q,
		sample_staff.sample_window
	ORDER BY 
		sample_window.letter,
		sample_window.id 
	) AS q
ORDER BY 
	id,
    letter
; -- using MYsql 5.7
/* when we add DISTINCT then DENSE_RANK( islike ROW_NUMBER() */
SELECT DISTINCT
    #sample_window.id AS id,
    sample_window.letter AS letter,
    DENSE_RANK() OVER (
		-- PARTITION BY sample_window.letter
		ORDER BY sample_window.letter
	) AS `rank`
FROM 
	sample_staff.sample_window
ORDER BY 
	letter#,	id    
; -- using MYsql 8.0
/*+---+--------+------+
|   | letter | rank |
+---+--------+------+
|   | a      | 1    |
|   | b      | 2    |
|   | c      | 3    |
|   | d      | 4    |
|   | e      | 5    |
+---+--------+------+*/
SELECT DISTINCT 
	#id,
    letter,
    #`row_number`,
    `rank`
FROM (
	SELECT 
		#sample_window.id AS id,
		sample_window.letter AS letter,
		#@row_number := @row_number + 1 AS `row_number`,
        IF(@prev IS NULL, @prev := sample_window.letter, IF(@prev != sample_window.letter, @rank := @rank + 1, @prev)),
        IF(@prev != sample_window.letter, @prev := sample_window.letter, @prev),
        @rank AS `rank`
	FROM 
		(SELECT @row_number := 0, @rank := 1, @prev := NULL) as q,
		sample_staff.sample_window
	ORDER BY 
		sample_window.letter#,
		#sample_window.id 
	) AS q
ORDER BY 
	#id,
    letter
; -- using MYsql 5.7

/* All the 3 functions together */
SELECT 
    sample_window.letter AS letter,
    ROW_NUMBER() OVER (ORDER BY sample_window.id) row_num,
    RANK() OVER (ORDER BY sample_window.letter) AS `rank`,
    DENSE_RANK() OVER (ORDER BY sample_window.letter) AS `dense_rank`
FROM 
	sample_staff.sample_window
ORDER BY 
	letter    
; -- using MYsql 8.0
/*+--------+---------+------+------------+
| letter | row_num | rank | dense_rank |
+--------+---------+------+------------+
| a      | 1       | 1    | 1          |
+--------+---------+------+------------+
| a      | 2       | 1    | 1          |
| a      | 3       | 1    | 1          |
| b      | 4       | 4    | 2          |
| c      | 5       | 5    | 3          |
| c      | 6       | 5    | 3          |
| d      | 7       | 7    | 4          |
| e      | 8       | 8    | 5          |
+--------+---------+------+------------+*/
/* ---- LAG(value anyelement [,offset integer [,default anyelement ]]) 
	returns: same type as value
returns value evaluated at the row that is offset rows BEFORE the
current row within the partition; if there is no such row, instead
return default (which must be of the same type as value). Both
offset and default are evaluated with respect to the current row.
If omitted, offset defaults to 1 and default to null
*/
SELECT 
    sample_window.letter AS letter,
    LAG(sample_window.letter) OVER (ORDER BY sample_window.letter) lag_letter,
    LEAD(sample_window.letter) OVER (ORDER BY sample_window.letter) lead_letter
FROM 
	sample_staff.sample_window
ORDER BY 
	letter    
; -- using MYsql 8.0
/* ---- LEAD() - same as LAG but offset is AFTER the current row */
/* ---- FIRST_VALUE(value any)same typeas value
returns value evaluated at the row that is the first row of the window frame
	LAST_VALUE(value any) same type as value 
returns value evaluated at the row that is the last row of the window frame
	NTH_VALUE(value any, nth integer) same type as value 
returns value evaluated at the row that is the nth row of the window frame (counting from 1); null if no such row

Note that first_value, last_value, and nth_value consider only the rows within the "window
frame", which by default contains the rows from the start of the partition through the last peer of the
CURRENT ROW. 
This is likely to give UNHELPFUL results for last_value and sometimes also nth_value.
You can redefine the frame by adding a suitable frame specification (RANGE or ROWS) to the OVER
clause. See Section 4.2.8 for more information about frame specifications.
*/
SELECT 
    sample_window.letter AS letter,
    FIRST_VALUE(sample_window.letter) OVER (ORDER BY sample_window.letter) 1st_letter,
    NTH_VALUE(sample_window.letter, 4) OVER (ORDER BY sample_window.letter) nth_letter,
    LAST_VALUE(sample_window.letter) OVER (ORDER BY sample_window.letter) last_letter
FROM 
	sample_staff.sample_window
ORDER BY 
	letter    
; -- using MYsql 8.0
/*  ---S06-P01----------------  Analytic functions - Practice -----------------
There are stats about user logins saved in sample_staff.user_stat. 
Create a query using row number to identify top 3 user that login most per day per hour. 
The output table should have the following attributes: date, hour, user_id, login_count
For each combination date-hour return max 3 users.
*/
SELECT *
FROM sample_staff.user_stat
;

    
    



