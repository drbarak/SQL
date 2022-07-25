/*  ---S04-L01----------------  Partitions ----------------
	can split tables into partitions, by Range, by Hash, by List or by Key
Range - PARTITION BY RANGE(xxx) ... PARTITION pXXX VALUES LESS THAN (xxxx)
List - PARTITION BY LIST(xxx) ... PARTITION pXXX VALUES IN ('X', 'Y', 'Z')
Hash - PARTITION BY HASH( MONTH(invoiced_date)
Sub-partitioning

A partition is a kind of an INDEX with pointers to the rows
*/

CREATE TABLE `test` (`id` INT, `purchased` DATE)
  PARTITION BY RANGE( YEAR(`purchased`) )
  SUBPARTITION BY HASH( TO_DAYS(`purchased`) )
  SUBPARTITIONS 10 (
    PARTITION p0 VALUES LESS THAN (1990),
    PARTITION p1 VALUES LESS THAN (2000),
    PARTITION p2 VALUES LESS THAN MAXVALUE
  )
;

-- 460ms
SELECT * /* Select without specifying a partition */
FROM `sample_staff`.`invoice`
WHERE 1=1
	AND YEAR(`invoice`.`invoiced_date`) = '1986'
	AND MONTH(`invoice`.`invoiced_date`) = 3
LIMIT 10
;
-- 1ms
SELECT * /* Select within a particular partition */
FROM `sample_staff`.`invoice` PARTITION (`p1986sp3`)
WHERE 1=1
	AND YEAR(`invoice`.`invoiced_date`) = '1986'
	AND MONTH(`invoice`.`invoiced_date`) = 3
LIMIT 10
;
SELECT * /* Select within a particular partition */
FROM `sample_staff`.`invoice` PARTITION (`p1986sp3`)
LIMIT 10
;
SELECT *
FROM sample_staff.invoice PARTITION (p1986)
WHERE 1=1
	AND YEAR(invoice.invoiced_date) = 1986
; -- 0.68 seconds
SELECT *
FROM sample_staff.invoice #PARTITION (p1986)
WHERE 1=1
	AND YEAR(invoice.invoiced_date) = 1986
; -- 1.16 seconds

-- list all partitions in a table
SELECT /* Select a list of all partitions from a table */
	`table_name`,
	`partition_ordinal_position`,
	`table_rows`,
	`partition_method`,
	`partitions`.*
FROM information_schema.partitions
WHERE 1=1
	AND `table_schema` = 'sample_staff'
	AND `table_name` = 'invoice'
ORDER BY table_rows DESC
;

/*  ---S04-L02----------------  Partitions  By Range ----------------
A table that is partitioned by range is partitioned in such a way that each partition contains rows
for which the partitioning expression value lies within a given range. 
Ranges should be contiguous but not overlapping, and are defined using the VALUES LESS THAN operator
The upper limit of the range can be defined using the keywork MAXVALUE
If there is no partition with MAXVALUE and insert with value greater than all the partitions, and error
will occur
	VALUES LESS THAN value must be strictly  increasing for each partition
If need to reorganize the PARTITIONS can use the REORGANIZE option of ALTER TABLE

NOTE: every unique key on the table must use every column in the table's partitioning expression.
Which means, if we want to define a UNIQUE key in the tbale, it must include the partitioning columns as well
*/

DROP TABLE IF EXISTS test;
CREATE TABLE test (id INT, purchased DATE)
	PARTITION BY RANGE (YEAR(purchased)) (
		PARTITION p0 VALUES LESS THAN (2000),
        PARTITION p1 VALUES LESS THAN (2010)
	)
;
INSERT INTO test(id, purchased)
VALUES
	(1, '1990-01-01'),
    (2, '2001-01-01'),
    (3, '2011-01-01')
; -- gives an error

ALTER TABLE test ADD PARTITION (PARTITION p3 VALUES LESS THAN MAXVALUE);

INSERT INTO test(id, purchased)
VALUES
	(1, '1990-01-01'),
    (2, '2001-01-01'),
    (3, '2011-01-01')
; -- Now no error

#EXPLAIN
SELECT *
FROM test;

SELECT 
	PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE 1=1
	and TABLE_NAME='test'
; -- one row per partition

/* now we want to split partition p0 to values up to year 1990 and upto 2000 */
ALTER TABLE test
    REORGANIZE PARTITION p0 INTO (
        PARTITION n2 VALUES LESS THAN (1990),
        PARTITION n3 VALUES LESS THAN (2000)
);

SELECT 
	PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE 1=1
	and TABLE_NAME='test'
; -- one row per partition

DROP TABLE IF EXISTS test;
CREATE TABLE test (id INT, purchased DATE)
    PARTITION BY HASH(id)
    PARTITIONS 6	/* used only with HASH partitions, automatically divides the row among the partitions */
;
INSERT INTO test(id, purchased)
VALUES
	(1, '1990-01-01'),
    (2, '2001-01-01'),
    (3, '2011-01-01')
;
    
SELECT 
	PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE 1=1
	and TABLE_NAME='test'
; 
/* multiple types of Partitions
3 partitions BY RANGE
and each one of them splits into 10 sub-Partitions
The engine decides to which partition based on the range, 
and then hash the field and places the row into the proper partition
*/
DROP TABLE IF EXISTS test;
CREATE TABLE `test` (`id` INT, `purchased` DATE)
  PARTITION BY RANGE( YEAR(`purchased`) )
  SUBPARTITION BY HASH( TO_DAYS(`purchased`) )
  SUBPARTITIONS 10 (
    PARTITION p0 VALUES LESS THAN (1990),
    PARTITION p1 VALUES LESS THAN (2000),
    PARTITION p2 VALUES LESS THAN MAXVALUE
  )
;

/*  ---S04-P03----------------  Partitions Practice ----------------
Create a new table sample_staff.invoice_partitioned based on sample_staff.invoice, but change the following:
	and add one more column: department_code
	remove the current partitions & sub-partitions
Then, copy data from invoice to the new table and also fill in the new column based on the department 
which the user was a part at the time of invoiced_date.
Add new LIST partitioning to invoice based on the department_code (see sample_staff.department.code).
*/

DROP TABLE IF EXISTS invoice_partitioned;
CREATE TABLE sample_staff.invoice_partitioned LIKE sample_staff.invoice;
-- can not remove all partitions using DROP (get an error) but can be doen by using REMOVE (see below)
ALTER TABLE sample_staff.invoice_partitioned 
	DROP PARTITION 
		p1984, p1985, p1986, p1987, p1988, p1989, p1990, p1991, p1991, p1992, p1993,
		pother;

SELECT 
	PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE 1=1
	and TABLE_NAME='invoice_partitioned'
; 

ALTER TABLE invoice_partitioned REMOVE PARTITIONING;
-- add the extra field afte copying the data so can use bulk INSERT
/* no need to do the insert in 2 steps
INSERT INTO invoice_partitioned
SELECT 
	invoice.*, 
    department.code AS department_code`
FROM invoice

	INNER JOIN sample_staff.department_employee_rel ON 1=1
		AND invoice.employee_id = department_employee_rel.employee_id
		AND invoice.invoiced_date BETWEEN department_employee_rel.from_date AND 
			IFNULL(department_employee_rel.to_date, '2002-08-01')

	INNER JOIN sample_staff.department ON 1=1
		AND department_employee_rel.department_id = department.id

Thus avoiding all the trouble of the UPDATE that nust use a SELECT that gives a single row
and a lot of other problems

UPDATE:
	After looking at the Q &A section of the course I understood that the problem arises from the fact that there
    are 62 records
*/
INSERT INTO invoice_partitioned SELECT * FROM invoice;
-- verify same size - all rows copied
select count(*) from invoice_partitioned;
select count(*) from invoice;

ALTER TABLE invoice_partitioned ADD department_code VARCHAR(35);

select department_code from invoice_partitioned where department_code IS NOT NULL LIMIT 100;

SET SQL_SAFE_UPDATES=0;
UPDATE invoice_partitioned
SET invoice_partitioned.department_code = (
	SELECT 
		department.`code` AS department_code
	FROM sample_staff.invoice
    
	INNER JOIN sample_staff.department_employee_rel ON 1=1
		AND invoice.employee_id = department_employee_rel.employee_id
		AND invoice.invoiced_date BETWEEN department_employee_rel.from_date AND 
			#IFNULL(department_employee_rel.to_date, '2002-08-01')
            IFNULL(DATE_SUB(department_employee_rel.to_date, INTERVAL 1 DAY), '2002-08-01')

	INNER JOIN sample_staff.department ON 1=1
		AND department_employee_rel.department_id = department.id
	
    WHERE 1=1
		AND invoice.id = invoice_partitioned.id
        AND invoice.invoiced_date = invoice_partitioned.invoiced_date
    )
WHERE 1=1
	AND invoice_partitioned.department_code IS NULL
;
SET SQL_SAFE_UPDATES=1;
/* 62 records have duplicates that the above subquery returns 2 records instaed of a single one
 and that is why we have the problem of completing the update, and getting the error thatthe subquery returns more than 1 row
The root of the problem is that the condition of invoiced_date BETWEEN 2 dates might have 2 rows because
the to_date of one row is equal to from_date of another row - there is overlap between the dates
So we have to change the condition so that if such case occurs, we reduce the to_date by 1 day
AS one sudent suggested, here is the revised condition
	AND `invoice`.`invoiced_date` BETWEEN `department_employee_rel`.`from_date` 
		AND IFNULL(DATE_SUB(`department_employee_rel`.`to_date`, INTERVAL 1 DAY), '2002-08-01')
*/
/*  at one point, in order to force the query to return one row I returnred COUNT(*) instead of 
	department_code, and that is why those 62 records had '2' in the field, ubstead of '1'
    After the above fix, I needed to change the '2' back to NULL and run the uUPDATE again
*/    
UPDATE invoice_partitioned
SET invoice_partitioned.department_code = NULL
WHERE department_code = '2';

SELECT id, invoiced_date, department_code 
FROM invoice_partitioned
WHERE department_code = '2' OR department_code IS NULL
; # after the fix no rows found
#GROUP BY department_code; # in order to find possible department_code, for the next part - partition by list

/* now add a LIST partition - we must use LIST COLUMNNS becuase the code is non integer
However, we get an error that the column is not a PRIMARY key
so we must add it to the PRIMARY key - first drop the existing key and then add the new one
In order to drop the key we must first remove the autoincreament property of the 'id' field, then set it up again
`id` int unsigned NOT NULL AUTO_INCREMENT,
*/
ALTER TABLE invoice_partitioned MODIFY id INT NOT NULL;
ALTER TABLE invoice_partitioned DROP PRIMARY KEY;
 
ALTER TABLE invoice_partitioned ADD PRIMARY KEY (id, invoiced_date, department_code);
ALTER TABLE invoice_partitioned MODIFY id INT NOT NULL AUTO_INCREMENT;
    
ALTER TABLE invoice_partitioned
	PARTITION BY LIST COLUMNS(department_code)	(
		PARTITION pMKT VALUES IN ('MKT'), 
		PARTITION pHR VALUES IN ('HR'), 
        PARTITION pFIN VALUES IN ('FIN'),
        PARTITION pRES VALUES IN ('RES'),
        PARTITION pQA VALUES IN ('QA'),
        PARTITION pSAL VALUES IN ('SAL'),
        PARTITION pDEV VALUES IN ('DEV'),
        PARTITION pCS VALUES IN ('CS'),
		PARTITION pPROD VALUES IN ('PROD')
        );

SELECT *
FROM invoice_partitioned PARTITION (pRES)
; -- took 0.156 seconds for 55,458 rows