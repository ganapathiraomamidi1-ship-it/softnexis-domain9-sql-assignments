-- Domain 9 / SQL Task 2: Data Aggregation & Reporting
-- MySQL 8+; Employees Sample Database.

-- 1. Current department salary summary.
SELECT d.dept_name AS department,
       COUNT(DISTINCT e.emp_no) AS employees,
       ROUND(AVG(s.salary), 2) AS avg_salary,
       MIN(s.salary) AS min_salary,
       MAX(s.salary) AS max_salary,
       MAX(s.salary) - MIN(s.salary) AS salary_range
FROM departments AS d
JOIN dept_emp AS de ON de.dept_no = d.dept_no
JOIN employees AS e ON e.emp_no = de.emp_no
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE de.to_date > CURDATE()
  AND s.to_date > CURDATE()
GROUP BY d.dept_name
ORDER BY avg_salary DESC;

-- 2. Yearly hiring trend with year-over-year change and growth rate.
WITH hires_by_year AS (
    SELECT YEAR(hire_date) AS hire_year,
           COUNT(*) AS new_hires
    FROM employees
    GROUP BY YEAR(hire_date)
),
trend AS (
    SELECT hire_year,
           new_hires,
           LAG(new_hires) OVER (ORDER BY hire_year) AS previous_year_hires
    FROM hires_by_year
)
SELECT hire_year,
       new_hires,
       new_hires - previous_year_hires AS yoy_change,
       ROUND(100.0 * (new_hires - previous_year_hires)
             / NULLIF(previous_year_hires, 0), 1) AS growth_rate_pct
FROM trend
WHERE hire_year BETWEEN 1985 AND 1995
ORDER BY hire_year;

-- 3. High-earning departments: filter groups with HAVING.
SELECT d.dept_name,
       ROUND(AVG(s.salary)) AS avg_salary,
       COUNT(DISTINCT e.emp_no) AS current_employees
FROM departments AS d
JOIN dept_emp AS de ON de.dept_no = d.dept_no
JOIN employees AS e ON e.emp_no = de.emp_no
JOIN salaries AS s ON s.emp_no = e.emp_no
WHERE de.to_date > CURDATE()
  AND s.to_date > CURDATE()
GROUP BY d.dept_name
HAVING AVG(s.salary) > 70000
   AND COUNT(DISTINCT e.emp_no) > 10000
ORDER BY avg_salary DESC;

-- 4. Salary distribution by $10,000 buckets within Sales.
WITH sales_salary_buckets AS (
    SELECT d.dept_name,
           FLOOR(s.salary / 10000) * 10000 AS salary_bucket,
           COUNT(*) AS salary_records
    FROM departments AS d
    JOIN dept_emp AS de ON de.dept_no = d.dept_no
    JOIN salaries AS s ON s.emp_no = de.emp_no
    WHERE de.to_date > CURDATE()
      AND s.to_date > CURDATE()
      AND d.dept_name = 'Sales'
    GROUP BY d.dept_name, FLOOR(s.salary / 10000) * 10000
)
SELECT dept_name,
       salary_bucket,
       salary_records,
       CONCAT(ROUND(100.0 * salary_records
                    / SUM(salary_records) OVER (PARTITION BY dept_name), 1), '%')
           AS distribution
FROM sales_salary_buckets
ORDER BY salary_bucket;

-- Quality checks: current salary population and missing department numbers.
SELECT COUNT(DISTINCT emp_no) AS employees_with_current_salary
FROM salaries
WHERE to_date > CURDATE();

SELECT COUNT(*) AS assignments_with_missing_department
FROM dept_emp
WHERE dept_no IS NULL;

-- Example consistency check: group totals should match the distinct current
-- employee population when each employee has one current department.
SELECT SUM(department_employee_count) AS total_in_department_reports
FROM (
    SELECT d.dept_name, COUNT(DISTINCT de.emp_no) AS department_employee_count
    FROM departments AS d
    JOIN dept_emp AS de ON de.dept_no = d.dept_no
    WHERE de.to_date > CURDATE()
    GROUP BY d.dept_name
) AS department_totals;

-- Common error: WHERE filters rows before aggregation; HAVING filters groups.
-- Correct pattern for average salary over $50,000:
SELECT d.dept_name, AVG(s.salary) AS avg_salary
FROM departments AS d
JOIN dept_emp AS de ON de.dept_no = d.dept_no
JOIN salaries AS s ON s.emp_no = de.emp_no
WHERE de.to_date > CURDATE()
  AND s.to_date > CURDATE()
GROUP BY d.dept_name
HAVING AVG(s.salary) > 50000;

-- Avoid a divide-by-zero error when the denominator can be zero:
-- SELECT SUM(revenue) / NULLIF(COUNT(*), 0) AS average_revenue
-- FROM some_reporting_source;

