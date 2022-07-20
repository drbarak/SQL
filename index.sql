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