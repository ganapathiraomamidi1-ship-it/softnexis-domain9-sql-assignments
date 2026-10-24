# Domain 9 SQL Assignments

Four MySQL scripts for the SoftNexis Domain 9 SQL task sheets.

## Contents

- `task-1-basic-retrieval.sql` — column selection, expressions, filters, sorting, pagination, and validation.
- `task-2-aggregation-reporting.sql` — department summaries, hiring trends, `HAVING`, salary buckets, and quality checks.
- `task-3-multi-table-joins.sql` — joins, correlated subqueries, `UNION ALL`, distinct values, gender ratios, and query-plan guidance.
- `task-4-data-modification-integrity.sql` — sandbox setup, CRUD operations, constraints, transactions, savepoints, and validation.

## Database

The scripts target MySQL 8.0+ and the Employees Sample Database (`employees`, `departments`, `dept_emp`, `dept_manager`, `salaries`, and `titles`). Date filters use `CURDATE()` so “current” rows follow the database's date.

Task 4 confines modifications to sandbox tables. Review the setup and run it in a practice schema; do not point its modification examples at production tables.

The SQL is prepared but has not been run against a connected MySQL database. The Task 2 attachment is now readable in the SoftNexis dashboard these scripts reflect all four task sheets.

