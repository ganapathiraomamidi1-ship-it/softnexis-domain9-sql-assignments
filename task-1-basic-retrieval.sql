-- Domain 9 / SQL Task 1: Basic Data Retrieval & Filtering
-- MySQL 8+; Employees Sample Database.

-- 1. Select only the columns needed.
SELECT emp_no, first_name, last_name, hire_date
FROM employees
ORDER BY hire_date DESC
LIMIT 20;

-- 2. Return a calculated salary column for current salary records.
SELECT e.emp_no,
       CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
       s.salary AS current_salary,
       ROUND(s.salary * 1.10, 2) AS salary_after_10pct_increase
FROM employees AS e
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE s.to_date > CURDATE()
ORDER BY s.salary DESC
LIMIT 20;

-- 3. Equality, numeric comparisons, and a date range.
SELECT emp_no, first_name, last_name, hire_date
FROM employees
WHERE gender = 'F'
  AND hire_date BETWEEN '1990-01-01' AND '1999-12-31'
ORDER BY hire_date ASC;

-- 4. Text pattern matching with LIKE and NOT LIKE.
SELECT emp_no, first_name, last_name
FROM employees
WHERE last_name LIKE 'S%'
  AND first_name NOT LIKE '%a%'
ORDER BY last_name, first_name;

-- 5. Combine AND/OR explicitly with parentheses.
SELECT e.emp_no,
       e.first_name,
       e.last_name,
       s.salary
FROM employees AS e
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE s.to_date > CURDATE()
  AND (e.gender = 'F' OR e.hire_date >= '2020-01-01')
  AND s.salary > 50000
ORDER BY s.salary DESC;

-- 6. Find employees without a current department assignment (NULL handling).
SELECT e.emp_no, e.first_name, e.last_name
FROM employees AS e
LEFT JOIN dept_emp AS de
       ON de.emp_no = e.emp_no
      AND de.to_date > CURDATE()
WHERE de.dept_no IS NULL
ORDER BY e.emp_no
LIMIT 100;

-- 7. Combined sort: department ascending, then salary descending.
SELECT d.dept_name,
       e.emp_no,
       e.first_name,
       e.last_name,
       s.salary
FROM departments AS d
JOIN dept_emp AS de ON de.dept_no = d.dept_no
JOIN employees AS e ON e.emp_no = de.emp_no
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE de.to_date > CURDATE()
  AND s.to_date > CURDATE()
ORDER BY d.dept_name ASC, s.salary DESC
LIMIT 100;

-- 8. Paginate results (page size 25; this is page 2).
SELECT emp_no, first_name, last_name, hire_date
FROM employees
ORDER BY emp_no
LIMIT 25 OFFSET 25;

-- 9. Business question: Marketing hires in 2023 earning over $50,000.
SELECT e.first_name,
       e.last_name,
       e.hire_date,
       d.dept_name,
       s.salary
FROM employees AS e
JOIN dept_emp AS de ON de.emp_no = e.emp_no
JOIN departments AS d ON d.dept_no = de.dept_no
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE de.to_date > CURDATE()
  AND s.to_date > CURDATE()
  AND d.dept_name = 'Marketing'
  AND e.hire_date >= '2023-01-01'
  AND e.hire_date < '2024-01-01'
  AND s.salary > 50000
ORDER BY e.hire_date, e.last_name, e.first_name;

-- 10. Validation query from the task sheet: Sales hires in the 1990s
-- whose last name begins with S. Check the actual values in this database;
-- the task sheet labels its sample numbers as examples.
SELECT COUNT(*) AS total_filtered,
       MIN(s.salary) AS min_current_salary,
       MAX(e.hire_date) AS latest_hire
FROM employees AS e
JOIN dept_emp AS de ON de.emp_no = e.emp_no
JOIN departments AS d ON d.dept_no = de.dept_no
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE d.dept_name = 'Sales'
  AND de.to_date > CURDATE()
  AND s.to_date > CURDATE()
  AND e.hire_date BETWEEN '1990-01-01' AND '1999-12-31'
  AND e.last_name LIKE 'S%';

