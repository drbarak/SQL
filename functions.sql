/*  ---S07-L01----------------  Functions -----------------*/

DROP FUNCTION IF EXISTS `FC_IS_MULTINIGHT`;

DELIMITER //
CREATE FUNCTION `FC_IS_MULTINIGHT`(
	checkin_date DATE,
	checkout_date DATE
) RETURNS TINYINT
DETERMINISTIC
BEGIN
	RETURN CASE
	  WHEN DATEDIFF(checkout_date, checkin_date) <= 1 THEN FALSE
	  ELSE TRUE
	END;
END;
//
DELIMITER ;

SELECT /* Is multinight? */
	@checkin_date := '2016-05-09' AS checkin_date,
	@checkout_date := '2016-05-08' AS checkout_date,
	FC_IS_MULTINIGHT(@checkin_date, @checkout_date) AS is_multinight
;

/*  ---S07-L02----------------  Coding standards for functions and procedures -----------------
1. Always use DELIMITER, even if it's not necessary
2. Split parameters on a new line
3. Uppercase keywords, lowercase parameters, variables and table/column names
4. Uppercase function and procedure names
5. Comment a lot
6. Add prefixes: Functions: FC_, Procedures: INS_ / DEL_ / UPD_ / SEL_
7. When saving code to repository, add delimiter & DELETE ... IF EXISTS
*/

/*  ---S07-L03----------------  Function options -----------------
DETERMINISTIC or not?
A routine is considered “deterministic” if it always produces the same result for the same input parameters, 
and “not deterministic” otherwise. 
If neither DETERMINISTIC nor NOT DETERMINISTIC is given in the routine definition, the default is NOT DETERMINISTIC. 
To declare that a function is deterministic, you must specify DETERMINISTIC explicitly.
A routine that contains the NOW() function (or its synonyms) or RAND() is nondeterministic.

SQL usage indication
CONTAINS SQL indicates that the routine does not contain statements that read or write data. 
This is the default if none of these characteristics is given explicitly. 
Examples of such statements are SET @x = 1 or DO RELEASE_LOCK('abc'), which execute but neither read nor write data.
NO SQL indicates that the routine contains no SQL statements.
READS SQL DATA indicates that the routine contains statements that read data (for example, SELECT), but not statements 
that write data.
MODIFIES SQL DATA indicates that the routine contains statements that may write data (for example, INSERT or DELETE).

SQL SECURITY
The SQL SECURITY characteristic can be DEFINER or INVOKER to specify the security context; 
that is, whether the routine executes using the privileges of the account named in the routine DEFINER clause or 
the user who invokes it. This account must have permission to access the database with which the routine is associated. 
The default value is DEFINER. The user who invokes the routine must have the EXECUTE privilege for it, 
as must the DEFINER account if the routine executes in definer security context.

DEFINER = 'user_name'@'host_name'
*/
DROP PROCEDURE IF EXISTS `SEL_EMPLOYEE_COUNT`;
DELIMITER //
CREATE DEFINER = `staff`@`%` PROCEDURE `SEL_EMPLOYEE_COUNT`()
SQL SECURITY INVOKER
BEGIN
  SELECT COUNT(*) FROM `sample_staff`.`employee`;
END;
//
DELIMITER ;

-- Call the new procedure
CALL SEL_EMPLOYEE_COUNT();
/*
Error: The user specified as a definer ('staff'@'%') does not exist
Create the missing user: CREATE USER 'staff' IDENTIFIED BY 'ASD1n232';
Error: execute command denied to user 'staff'@'%' for routine 'sample_staff.SEL_EMPLOYEE_COUNT'
Grant access: GRANT EXECUTE ON sample_staff.* to 'staff'@'%';
Error: SELECT command denied to user 'staff'@'%' for table 'employee'
Grant access: GRANT SELECT ON sample_staff.employee to 'staff'@'%';
*/

/*  ---S07-P01----------------  Function Practice -----------------
Create a function that will return distance between 2 coordinates in meters. 
Each coordinate is defined by latitude and longitude.
Pick 2 places on latlong.net, get their latitude & longitude, and use your newly created function 
to calculate distance between the 2 places.

Law of cosines
d = R ⋅ acos( sin φ1 ⋅ sin φ2 + cos φ1 ⋅ cos φ2 ⋅ cos Δλ )
*/