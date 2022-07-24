SELECT 
	employee.id AS employee_id, 
    concat(employee.first_name, ' ', employee.last_name) AS employee_full_name, 
    department.id AS department_id, 
    department.name AS last_department_name,
    max_department_employee_rel_id,
    salary.salary_amount,
    avg_salary
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

INNER JOIN (
	SELECT AVG(sample_staff.salary.salary_amount) as avg_salary
    FROM sample_staff.salary
	) as q

INNER JOIN
	salary ON 1=1
		AND salary.employee_id = employee.id
    
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