-- Domain 9 / SQL Task 4: Data Modification & Integrity
-- MySQL 8+; Employees Sample Database.
-- Safety: all examples operate on *_sandbox tables. Use a practice schema.

-- A. Create isolated copies. LIKE preserves the source columns and indexes;
-- INSERT IGNORE makes the small seed repeatable when primary keys match.
CREATE TABLE IF NOT EXISTS employee_sandbox LIKE employees;
INSERT IGNORE INTO employee_sandbox
SELECT * FROM employees ORDER BY emp_no LIMIT 1000;

CREATE TABLE IF NOT EXISTS departments_sandbox LIKE departments;
INSERT IGNORE INTO departments_sandbox
SELECT * FROM departments;

CREATE TABLE IF NOT EXISTS dept_emp_sandbox LIKE dept_emp;
INSERT IGNORE INTO dept_emp_sandbox
SELECT de.*
FROM dept_emp AS de
JOIN employee_sandbox AS e ON e.emp_no = de.emp_no
ORDER BY de.emp_no
LIMIT 5000;

CREATE TABLE IF NOT EXISTS salary_sandbox LIKE salaries;
INSERT IGNORE INTO salary_sandbox
SELECT s.*
FROM salaries AS s
JOIN employee_sandbox AS e ON e.emp_no = s.emp_no
ORDER BY s.emp_no, s.from_date
LIMIT 5000;

-- B. INSERT examples. Use unused employee numbers in this sandbox.
INSERT INTO employee_sandbox
    (emp_no, birth_date, first_name, last_name, gender, hire_date)
VALUES
    (500001, '1995-08-14', 'Emma', 'Johnson', 'F', '2023-06-01'),
    (500002, '1990-11-03', 'Liam', 'Smith', 'M', '2023-06-01'),
    (500003, '1988-04-22', 'Olivia', 'Brown', 'F', '2023-06-01');

SELECT emp_no, first_name, last_name, hire_date
FROM employee_sandbox
WHERE emp_no BETWEEN 500001 AND 500003
ORDER BY emp_no;

-- C. UPDATE examples with a narrow WHERE clause; verify before and after.
SELECT emp_no, first_name, last_name, hire_date
FROM employee_sandbox
WHERE emp_no = 500003;

UPDATE employee_sandbox
SET first_name = 'Amelia'
WHERE emp_no = 500003;

UPDATE employee_sandbox
SET hire_date = '2023-07-15'
WHERE emp_no = 10001;

SELECT emp_no, first_name, last_name, hire_date
FROM employee_sandbox
WHERE emp_no IN (500003, 10001);

-- D. DELETE test records only after checking the exact target set.
SELECT emp_no, first_name, hire_date
FROM employee_sandbox
WHERE hire_date = '2023-06-01'
  AND emp_no BETWEEN 500001 AND 500003;

DELETE FROM employee_sandbox
WHERE hire_date = '2023-06-01'
  AND emp_no BETWEEN 500001 AND 500003;

SELECT COUNT(*) AS remaining_test_rows
FROM employee_sandbox
WHERE emp_no BETWEEN 500001 AND 500003;

-- E. Primary-key violation example. Keep commented: it is expected to fail.
-- INSERT INTO employee_sandbox
--     (emp_no, birth_date, first_name, last_name, gender, hire_date)
-- VALUES (10001, '1953-09-02', 'John', 'Doe', 'M', '1986-06-26');

-- F. Add a foreign key after checking that all salary_sandbox emp_no values
-- exist in employee_sandbox. Run this ALTER only once per fresh sandbox.
-- ALTER TABLE salary_sandbox
--   ADD CONSTRAINT fk_salary_employee
--   FOREIGN KEY (emp_no) REFERENCES employee_sandbox(emp_no);

-- Expected foreign-key violation example (keep commented; expected to fail):
-- INSERT INTO salary_sandbox (emp_no, salary, from_date, to_date)
-- VALUES (999999, 80000, '2023-01-01', '9999-01-01');

-- G. Transaction and rollback: demonstrate atomic changes without keeping them.
START TRANSACTION;

UPDATE employee_sandbox
SET first_name = 'Alexander'
WHERE emp_no = 10002;

INSERT INTO salary_sandbox (emp_no, salary, from_date, to_date)
VALUES (10002, 75000, CURDATE(), '9999-01-01');

SELECT emp_no, first_name, last_name
FROM employee_sandbox
WHERE emp_no = 10002;

SELECT emp_no, salary, from_date, to_date
FROM salary_sandbox
WHERE emp_no = 10002
ORDER BY from_date DESC;

ROLLBACK;

-- H. Savepoint: retain one safe update and undo a risky delete.
START TRANSACTION;

UPDATE employee_sandbox
SET hire_date = '2023-01-01'
WHERE emp_no = 10003;

SAVEPOINT before_risky_delete;

-- Preview the target set before the delete.
SELECT emp_no, first_name
FROM employee_sandbox
WHERE first_name LIKE 'A%';

DELETE FROM employee_sandbox
WHERE first_name LIKE 'A%';

ROLLBACK TO SAVEPOINT before_risky_delete;
COMMIT;

-- I. Pre/post validation snapshot and row-count comparison.
CREATE TABLE IF NOT EXISTS employee_sandbox_snapshot LIKE employee_sandbox;
TRUNCATE TABLE employee_sandbox_snapshot;
INSERT INTO employee_sandbox_snapshot
SELECT * FROM employee_sandbox;

SELECT (SELECT COUNT(*) FROM employee_sandbox_snapshot) AS snapshot_rows,
       (SELECT COUNT(*) FROM employee_sandbox) AS current_rows;

-- Immutable-field validation example: compare before/after values in an
-- application transaction and roll back if a protected attribute changed.
-- The SQL check below can be adapted when a specific protected field is set.
SELECT COUNT(*) AS null_employee_numbers
FROM employee_sandbox
WHERE emp_no IS NULL;

-- J. Optional unique email constraint example. Run once; multiple NULL email
-- values are permitted by MySQL, but duplicate non-NULL values are rejected.
-- ALTER TABLE employee_sandbox ADD COLUMN email VARCHAR(255) NULL;
-- ALTER TABLE employee_sandbox
--   ADD CONSTRAINT uq_employee_sandbox_email UNIQUE (email);
-- UPDATE employee_sandbox
-- SET email = CONCAT('emp', emp_no, '@example.invalid')
-- WHERE email IS NULL;
-- This second update should fail because the value is a duplicate:
-- UPDATE employee_sandbox
-- SET email = 'duplicate@example.invalid'
-- WHERE emp_no IN (10001, 10002);

-- K. Controlled department consolidation in the sandbox only.
-- Confirm the target department exists before running this transaction.
-- START TRANSACTION;
-- UPDATE dept_emp_sandbox
-- SET dept_no = (SELECT dept_no FROM departments_sandbox
--                WHERE dept_name = 'People Ops')
-- WHERE dept_no = (SELECT dept_no FROM departments_sandbox
--                  WHERE dept_name = 'Human Resources')
--   AND to_date > CURDATE();
-- SELECT COUNT(*) AS remaining_active_hr_assignments
-- FROM dept_emp_sandbox
-- WHERE dept_no = (SELECT dept_no FROM departments_sandbox
--                  WHERE dept_name = 'Human Resources')
--   AND to_date > CURDATE();
-- ROLLBACK; -- Keep this practice scenario reversible.

-- L. Audited purge example in the sandbox; keep reversible until verified.
CREATE TABLE IF NOT EXISTS deletion_audit (
    emp_no INT NOT NULL,
    delete_date DATE NOT NULL,
    PRIMARY KEY (emp_no)
);

START TRANSACTION;

INSERT IGNORE INTO deletion_audit (emp_no, delete_date)
SELECT emp_no, CURDATE()
FROM employee_sandbox
WHERE hire_date < '1990-01-01';

DELETE FROM employee_sandbox
WHERE hire_date < '1990-01-01';

SELECT COUNT(*) AS pre_1990_rows_remaining
FROM employee_sandbox
WHERE hire_date < '1990-01-01';

ROLLBACK;

-- Transaction safety checklist:
-- 1. Preview UPDATE/DELETE targets with SELECT.
-- 2. Use a transaction and validate before COMMIT.
-- 3. Keep an audit trail for intentional deletions.
-- 4. Do not run sandbox examples against production tables.

