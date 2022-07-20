# mysql-ctl cli;
# source PA_sql_1.sql;

#SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
#set sql_mode = ONLY_FULL_GROUP_BY;

DROP DATABASE IF EXISTS PA_sql;
CREATE DATABASE PA_sql;
USE PA_sql; 

/* Beutify the code
Simple rules to start with:
    Use inline comments
    Use tabs instead of spaces
    Use 1=1
    Split column names to new lines
    Add empty lines for complex queries
    Do not shorten table name aliases
    Use the backtick (`) before and after table & column names
*/
# before
SELECT CONCAT('2&', GROUP_CONCAT(B SEPARATOR '&'))
FROM (
    SELECT DISTINCT B FROM (
    SELECT A, B FROM
        (SELECT @max := 100)as tmp,
        (SELECT @A := @A + 1 AS A from t, (select @A := 1) as qa/*, t as t1*/) as q, 
        (SELECT @B := @B + 1 AS B from t, (select @B := 1) as qb/*, t as t1*/) as q1
    WHERE B > A AND B <= @max) AS q
WHERE B NOT IN (
    SELECT B FROM (
        SELECT A, B FROM
        (SELECT @X := @X + 1 AS A from t, (select @X := 1) as qa/*, t as t1*/) as q, 
        (SELECT @Y := @Y + 1 AS B from t, (select @Y := 1) as qb/*, t as t1*/) as q1
        WHERE B > A AND B <= @max) as q2
    WHERE MOD(B, A) = 0
    )
) qx;

# after
SELECT /* all prine numbers separted by '&' */
	CONCAT('2&', GROUP_CONCAT(B SEPARATOR '&')) /* 2 is the first prime number, all the others are concatinated to it */
FROM (
    SELECT  /* the prime numbers */ 
    	DISTINCT B 
    FROM (
        SELECT 
        	A, 
        	B 
        FROM
            (SELECT @max := 100) AS tmp,	/* set the value of @max */
            (SELECT 
             	@A := @A + 1 AS A 		/* increament value of @A */
            FROM 
             	t, 
             	(SELECT @A := 1) AS qa	/* set init value of @A */
            ) as q, 
            (SELECT 
             	@B := @B + 1 AS B		/* increament value of @B */
             FROM 
             	t, 
             	(SELECT @B := 1) AS qb 	/* set init value of @B */
            ) AS q1
	    WHERE 1=1
        	AND B > A 
        	AND B <= @max
    ) AS q
WHERE 1=1
    AND B NOT IN (
    	SELECT 
        	B 
        FROM (
        	SELECT 
            	A,
            	B 
            FROM
        		(SELECT 
                	@X := @X + 1 AS A 
                 FROM
                 	t, 
                 	(SELECT @X := 1) AS qa
                ) AS q, 
        		(SELECT 
                 	@Y := @Y + 1 AS B 
                 FROM 
                 	t,
                 	(SELECT @Y := 1) AS qb
                ) as q1
        WHERE 1=1
            AND B > A 
            AND B <= @max
        ) as q2
    WHERE 1=1
        AND MOD(B, A) = 0
    )
) AS qx;

/* ---- Best practices ------------------
Practice advanced SQL with MySQL
1. Store code in a git repository
2. Do not use select *
3. Separate attributes (columns) to rows

Query: Select employees' profile photos.

Not so good: A comma separated list of attributes in one line:
*/
SELECT
`employee`.`first_name`, `employee`.`last_name`, `employee`.`email`,
`employee`.`gender`, CONCAT(`photo`.`path`, `photo`.`filename`) AS
profile_photo
FROM `sample_staff`.`employee`
INNER JOIN `photo` ON `photo`.`employee_id` = `employee`.`id`
AND `photo`.`profile_photo_flag` = 1
AND `photo`.`deleted_flag` = 0
WHERE 1=1
AND `employee`.`deleted_flag` = 0
ORDER BY
`employee`.`id`
LIMIT 1000
;

#A better version (attributes split on multiple lines):

SELECT
Practice advanced SQL with MySQL
Page 3/9 © Copyright 2016 Michal Juhas
`employee`.`first_name`,
`employee`.`last_name`,
`employee`.`email`,
`employee`.`gender`,
CONCAT(`photo`.`path`, `photo`.`filename`) AS profile_photo
FROM `sample_staff`.`employee`
...
;
/*
4. Set naming convention and don’t allow exceptions
Consistency is the key.
    * tables & columns (lower-case, snake-form)
    * keys (suffix _id )
    * date columns suffix _date
    * datetime columns suffix _datetime or _dt
    * indexes (prefix: idx_ , ak_ )
    * table or column names always always always in singular
    * flag indication (1=yes, 0=no, -1=unknown) always suffix _flag (
    		TINYINT NOT NULL DEFAULT -1 )
    * separate integer ID's and varchar codes * suffix _id for INTEGER (11) * suffix _code
    	for VARCHAR (35)
        
5. Be descriptive, don’t use acronyms
    At HotelQuickly, 3 years ago we started using acronyms such as:
    cnt = count
    amt = amount
    catg = category
    ins = insert
    and several others, but eventually very cumbersome to maintain.
    Recommendation: be descriptive and always use full words. A simple rule like this can help a lot.
    count (i.e. max_use_count )
    amount (i.e. voucher_amount )
    category (i.e. hotel_category_id )
    insert (i.e. insert_user_id )
6. Use audit columns
    insert_dt - type DATETIME - time when the row was inserted (use NOW() at the time of insert)
    insert_user_id - type INT (11) - a user (if logged in) who inserted the row
    insert_process_code - type VARCHAR (255) - a process, function or class which inserted the row
    update_dt - type TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP - automatically changed
    update_user_id - type INT (11) - a user (if logged in) who modified the row
    update_process_code - type VARCHAR (255) - a process, function or class which inserted the row
    deleted_flag - type TINYINT (4) NOT NULL DEFAULT 0 - use values 0 or 1 ,nothing else
7. Batch delete & updates (example)
    With 1+ mil. rows it will be slow (table locked, transactions piled up).
    DELETE FROM salary
    WHERE to_date IS NOT NULL
    This will be faster, but you need to run it 100+ times in a loop cycle. Stored procedures are good
    for this.
    DELETE FROM salary
    WHERE to_date IS NOT NULL
    LIMIT 10000
    For example in PHP:
    while (1) {
    mysql_query("DELETE FROM salary WHERE to_date IS NOT NULL LIMIT
    10000");
    if (mysql_affected_rows() == 0) {
    // done deleting
    break;
    }
    // you can even pause for a few seconds
    sleep(5);
    }
8. Reference the owner of the object
    Always add a table name before column name.
    Classic scenario - you start with a simple query:
    SELECT
    id AS employee_id,
    first_name,
    last_name
    FROM employee
    WHERE 1=1
    AND deleted_flag = 0
    LIMIT 100
    ;
    Commit to git. Then decide to join another table (i.e. contract ) and suddenly you need to
    rewrite half of the query because both id and deleted_flag would be in both tables...
    #cumbersome
    
9. Table names always singular
    Imagine a list of tables in one schema:
        employee
        contracts
        employee_contracts_rel
    And now try to write a query
    SELECT
    .... /* fill in */
    FROM employee
    INNER JOIN contracts ON 1=1
    .... /* fill in */
    WHERE 1=1
    AND employee.deleted_flag = 0
    ;
    It can be even worse in NoSQL data storage...
    
10. WHERE 1=1 (and / or)

11. Old vs. new JOIN style
    Old style:
    SELECT
        employee.id,
        employee.full_name,
        contract.start_date
    FROM employee, contract, lst_contract_tp
    WHERE 1=1
        AND employee.id = employee_contract_rel.employee_id
        AND lst_contract_tp.id = contract.contract_tp_id
        AND employee.deleted_flag = 0
        AND contract.deleted_flag = 0
    JOIN style: (and while improving it found out the above query is wrong)
    -------------
    SELECT
        employee.id,
        employee.full_name,
        contract.start_date
    FROM employee
    
    INNER JOIN contract ON 1=1
    	AND employee.id = contract.employee_id
        AND contract.deleted_flag = 0
        
    INNER JOIN employee_contract_rel ON 1=1
    	AND employee.id = employee_contract_rel.employee_id
        
    INNER JOIN lst_contract_tp ON 1=1
    	AND lst_contract_tp.id = contract.contract_tp_id
    
    WHERE 1=1
       AND employee.deleted_flag = 0
        
   
12. Prefix database objects 
	views with v_
	functions with fc_
    
13. Don’t use column row in ORDER BY
    SELECT
    employee.id AS employee_id
    FROM employee
    WHERE 1=1
    AND employee.deleted_flag = 0
    AND employee.birth_date >= '1960-01-01'
    AND employee.birth_date <= '1960-31-12'
    ORDER BY
    1  /* here it is ordered by the first field in the list, wnd if someone adds a field in front suddenly the query is different */
    LIMIT 1000
    ;
    
14. Use LIMIT 1 as much as possible
    (example)
    In your PHP code:
    $todayDate = ... // Define
    $sql = "SELECT birth_date FROM employee WHERE birth_date = {$todayDate}";
    $result = $connection->query($sql);
    if ($result->num_rows > 0) {
    echo "Yes, there's an employee with this birth date"
    } else {
    echo "Nobody is celebrating";
    }
    Better would be to use LIMIT 1 in case of a large dataset.
    
15. Use correct data type, it makes adifference (example: IP address)
    From varchar20 to integer unsigned ( 145.54.123.90 => 2436266842 ).
    INET_ATON(expr) http://dev.mysql.com/doc/refman/5.0/en/miscellaneousfunctions.
    html#function_inet-aton
    INET_NTOA(expr) http://dev.mysql.com/doc/refman/5.0/en/miscellaneousfunctions.
    html#function_inet-ntoa
    TRUNCATE ip_address_int;
    INSERT INTO ip_address_int (id, ip_address)
    SELECT
    id,
    INET_ATON(ip_address_varchar20.ip_address)
    FROM ip_address_varchar20
    -- 1. Make sure to analyze tables first
    ANALYZE TABLE ip_address_varchar20;
    Practice advanced SQL with MySQL
    Page 9/9 © Copyright 2016 Michal Juhas
    ANALYZE TABLE ip_address_int;
    -- 2. Verify that the count of rows in each table is the same
    select count(*) from ip_address_varchar20;
    select count(*) from ip_address_int;
    -- 3. Check the size of tables on disk (in MB)
    SELECT
    table_name,
    (data_length + index_length) / power(1024, 2) AS tablesize_mb
    FROM information_schema.tables
    WHERE 1=1
    AND table_name IN ('ip_address_varchar20', 'ip_address_int')
    ;
    -- Make sure you can get the same value
    SELECT ip_address FROM ip_address_varchar20 WHERE id = 16;
    SELECT INET_NTOA(ip_address) FROM ip_address_int WHERE id = 16;
*/

# quiz 1 --------------- Re-write and beautify this query from S01-L02.------------
select e.id AS employee_id, concat(e.first_name, ' ', e.last_name) AS employee_full_name, d.id AS department_id, d.name AS last_department_name from employee e inner join ( select der.employee_id, max(der.id) AS max_id from department_employee_rel der where der.deleted_flag = 0 group by der.employee_id ) derm ON derm.employee_id = e.id inner join department_employee_rel der ON der.id = derm.max_id and der.deleted_flag = 0 inner join department d ON d.id = der.department_id and d.deleted_flag = 0 where e.id IN (10010, 10040, 10050, 91050, 205357) and e.deleted_flag = 0 limit 100;
# version 1 - just beautify
SELECT 
	e.id AS employee_id, 
    concat(e.first_name, ' ', e.last_name) AS employee_full_name, 
    d.id AS department_id, 
    d.name AS last_department_name
FROM employee e 

INNER JOIN (
    SELECT 
    	der.employee_id,
    	MAX(der.id) AS max_id 
    FROM 
    	department_employee_rel der 
    WHERE 1=1
    	AND der.deleted_flag = 0 
    GROUP BY 
    	der.employee_id
) derm ON 1=1
	AND derm.employee_id = e.id 
    
INNER JOIN
	department_employee_rel der ON 1=1
    	AND der.id = derm.max_id 
        AND der.deleted_flag = 0
        
INNER JOIN 
	department d ON 1=1
    	AND d.id = der.department_id
        AND d.deleted_flag = 0

WHERE 1=1
	AND e.id IN (10010, 10040, 10050, 91050, 205357)
    AND e.deleted_flag = 0
    
LIMIT 100;

# version 2 - also re-write
SELECT 
	employee.id AS employee_id, 
    concat(employee.first_name, ' ', employee.last_name) AS employee_full_name, 
    department.id AS department_id, 
    department.name AS last_department_name
FROM employee

INNER JOIN (
    SELECT 
    	department_employee_rel.employee_id,
    	MAX(department_employee_rel.id) AS max_department_employee_rel_id 
    FROM 
    	department_employee_rel 
    WHERE 1=1
    	AND department_employee_rel.deleted_flag = 0 
    GROUP BY 
    	department_employee_rel.employee_id
) derm ON 1=1
	AND derm.employee_id = employee.id 
    
INNER JOIN
	department_employee_rel ON 1=1
    	AND department_employee_rel.id = derm.max_department_employee_rel_id 
        AND department_employee_rel.deleted_flag = 0
        
INNER JOIN 
	department ON 1=1
    	AND department.id = department_employee_rel.department_id
        AND department.deleted_flag = 0

WHERE 1=1
	AND employee.id IN (10010, 10040, 10050, 91050, 205357)
    AND employee.deleted_flag = 0
    
LIMIT 100;

# quiz 2 --------------- Create a new view v_user_login which will select user's recent logins. Attributes to select:

CREATE VIEW v_user_login
AS
    SELECT 
		user_login.id,
		user_login.user_id,
		`user`.`name`,
		user_login.ip_address,
        user_login.ip_address,  /* show in a standard notation xxx.xxx.xxx.xxx */ 
		user_login.login_dt
    FROM
    	user_login
        
    INNER JOIN
    	user ON 1=1
        	AND user.id = user_login.user_id
# --------- solution
CREATE OR REPLACE VIEW `sample_staff`.`v_user_login` AS
    SELECT
        `user_login`.`id` AS `user_login_id`,
        `user_login`.`user_id`,
        `user`.`name` AS `user_name`,
        `user_login`.`ip_address` AS `ip_address_integer`,
        INET_NTOA(`user_login`.`ip_address`) AS `ip_address`,
        `user_login`.`login_dt`
    FROM `sample_staff`.`user_login`
    
    INNER JOIN `sample_staff`.`user` ON 1=1
    	AND `user`.`id` = `user_login`.`user_id`
        
    WHERE 1=1
    	AND `user_login`.`deleted_flag` = 0
    ORDER BY
    	`user_login`.`id` DESC
-- LIMIT shouldn't be here, because the user_id restriction will be
-- outside of this view
;    

# quiz 3 (S02-P03) --------------- Beautify this query: (rewrite it to look beautiful and follow best-practices & style guidelines):

insert into bi_data.valid_offers (offer_id, hotel_id, price_usd, original_price, original_currency_code,
      checkin_date, checkout_date, breakfast_included_flag, valid_from_date, valid_to_date)
select of.id, of.hotel_id, of.sellings_price as price_usd, of.sellings_price as original_price,
    lc.code AS original_currency_code, of.checkin_date, of.checkout_date, of.breakfast_included_flag,
    of.offer_valid_from, of.offer_valid_to
from  enterprise_data.offer_cleanse_date_fix of, primary_data.lst_currency lc
where of.currency_id=1 and lc.id=1;

INSER INTO
	bi_data.valid_offers (
    	offer_id,
        hotel_id,
        price_usd,
        original_price,
        original_currency_code,
        checkin_date,
        checkout_date,
        breakfast_included_flag,
        valid_from_date,
        valid_to_date
    )
	SELECT 
    	offer_cleanse_date_fix.id,
        offer_cleanse_date_fix.hotel_id,
        offer_cleanse_date_fix.sellings_price AS price_usd,
        offer_cleanse_date_fix.sellings_price AS original_price,
		lst_currency.code AS original_currency_code,
        offer_cleanse_date_fix.checkin_date,
        offer_cleanse_date_fix.checkout_date,
        offer_cleanse_date_fix.breakfast_included_flag,
        offer_cleanse_date_fix.offer_valid_from,
        offer_cleanse_date_fix.offer_valid_to
	FROM 
    	enterprise_data.offer_cleanse_date_fix
	WHERE 1=1
    	AND offer_cleanse_date_fix.currency_id=1
        
    INNER JOIN
    	primary_data.lst_currency ON 1=1
        	AND lst_currency.id=1;
