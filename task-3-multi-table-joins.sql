-- Domain 9 / SQL Task 3: Multi-Table Operations & Joins
-- MySQL 8+; Employees Sample Database.

-- 1. INNER JOIN: current employee-to-department mapping.
SELECT e.emp_no,
       CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
       d.dept_name
FROM employees AS e
JOIN dept_emp AS de ON de.emp_no = e.emp_no
JOIN departments AS d ON d.dept_no = de.dept_no
WHERE de.to_date > CURDATE()
ORDER BY e.emp_no
LIMIT 5;

-- 2. LEFT JOIN: retain employees even when no current department or manager
-- is available. Keeping date filters in ON preserves unmatched employees.
SELECT e.emp_no,
       CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
       d.dept_name,
       CONCAT(m.first_name, ' ', m.last_name) AS manager_name
FROM employees AS e
LEFT JOIN dept_emp AS de
       ON de.emp_no = e.emp_no
      AND de.to_date > CURDATE()
LEFT JOIN departments AS d ON d.dept_no = de.dept_no
LEFT JOIN dept_manager AS dm
       ON dm.dept_no = de.dept_no
      AND dm.to_date > CURDATE()
LEFT JOIN employees AS m ON m.emp_no = dm.emp_no
ORDER BY e.emp_no
LIMIT 5;

-- 3. UNION ALL: active and former Sales department assignments.
SELECT de.emp_no, 'Active' AS assignment_status, d.dept_name
FROM dept_emp AS de
JOIN departments AS d ON d.dept_no = de.dept_no
WHERE de.to_date > CURDATE()
  AND d.dept_name = 'Sales'
UNION ALL
SELECT de.emp_no, 'Former' AS assignment_status, d.dept_name
FROM dept_emp AS de
JOIN departments AS d ON d.dept_no = de.dept_no
WHERE de.to_date <= CURDATE()
  AND d.dept_name = 'Sales'
ORDER BY emp_no, assignment_status
LIMIT 5;

-- 4. Correlated scalar subquery: current salary per employee.
SELECT e.emp_no,
       e.first_name,
       (
           SELECT s.salary
           FROM salaries AS s
           WHERE s.emp_no = e.emp_no
             AND s.to_date > CURDATE()
           ORDER BY s.from_date DESC
           LIMIT 1
       ) AS current_salary
FROM employees AS e
WHERE e.emp_no BETWEEN 10001 AND 10010
ORDER BY e.emp_no;

-- 5. DISTINCT: unique current job titles.
SELECT DISTINCT t.title AS current_title
FROM titles AS t
WHERE t.to_date > CURDATE()
ORDER BY current_title;

-- 6. Conditional aggregation: current department gender ratios.
SELECT d.dept_name,
       ROUND(100.0 * SUM(e.gender = 'F') / NULLIF(COUNT(*), 0), 1) AS female_pct,
       ROUND(100.0 * SUM(e.gender = 'M') / NULLIF(COUNT(*), 0), 1) AS male_pct,
       COUNT(*) AS current_assignments
FROM departments AS d
JOIN dept_emp AS de ON de.dept_no = d.dept_no
JOIN employees AS e ON e.emp_no = de.emp_no
WHERE de.to_date > CURDATE()
GROUP BY d.dept_name
HAVING COUNT(*) > 10000
ORDER BY d.dept_name;

-- 7. Performance investigation: inspect the plan before adding an index.
EXPLAIN ANALYZE
SELECT e.emp_no, MAX(s.salary) AS max_salary
FROM employees AS e
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE s.to_date > CURDATE()
GROUP BY e.emp_no
LIMIT 10;

-- Optional covering index for the join/filter above. Check existing indexes
-- first; do not create a duplicate index in a shared or production database.
-- CREATE INDEX idx_salaries_emp_to_date_salary
--     ON salaries (emp_no, to_date, salary);

-- Common error: a missing join condition creates a Cartesian product.
-- Always join through the relationship table, for example:
-- employees -> dept_emp -> departments.

-- Common error: LEFT JOIN followed by a right-table filter in WHERE removes
-- unmatched rows. Put optional-row filters in ON, as in query 2.

-- Common error: UNION branches must return the same number and compatible
-- types of columns. UNION removes duplicates; UNION ALL preserves them.

