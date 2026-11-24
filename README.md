# SQL Server Performance Tuning Lab

A hands-on lab that shows how to find and fix slow SQL Server queries.
Each case has a **slow version**, a **fixed version**, and a short note explaining **why** the fix works.

The data model is a simple lending system (customers, loans, repayments) with ~1 million repayment rows,
so the performance differences are real and easy to measure.

## What this lab covers

| # | Case | Problem | Fix |
|---|------|---------|-----|
| 01 | Missing index | Full table scan on a big table | Nonclustered index with `INCLUDE` columns |
| 02 | Non-SARGable filter | Function on a column (`YEAR(Date)`) blocks index seeks | Rewrite as a date range |
| 03 | Implicit conversion | `NVARCHAR` parameter vs `VARCHAR` column | Match the data types |
| 04 | Cursor / row-by-row | Cursor loop to update rows | One set-based `UPDATE` |
| 05 | Parameter sniffing | One plan reused for very different parameter values | `OPTION (RECOMPILE)` / `OPTIMIZE FOR` |
| 06 | Key lookups | Index seek + thousands of lookups | Covering index |
| 07 | Pagination | `OFFSET` on deep pages gets slower | Keyset (seek) pagination |
| 08 | `SELECT *` + scalar function | Scalar UDF runs once per row | Inline table-valued function |

## How to run

Requirements: SQL Server 2019+ (Developer or Express edition) and SSMS or Azure Data Studio.

1. Run `scripts/01_create_database.sql` — creates the `PerfLab` database and tables
2. Run `scripts/02_seed_data.sql` — loads test data (takes 1–3 minutes)
3. Open any file in `cases/` and run it section by section

Every case file turns on timing and IO stats:

```sql
SET STATISTICS IO, TIME ON;
```

Compare **logical reads** and **elapsed time** between the slow and fixed queries.
Turn on **Include Actual Execution Plan** (Ctrl+M) to see the plan change.

## My results

Results on my machine (fill in after running — numbers depend on hardware):

| Case | Slow: logical reads / ms | Fixed: logical reads / ms |
|------|--------------------------|---------------------------|
| 01 | | |
| 02 | | |
| 03 | | |
| 04 | | |
| 05 | | |
| 06 | | |
| 07 | | |
| 08 | | |

## Tools used for diagnosis

`scripts/03_diagnostics.sql` has queries for:
- Top queries by CPU and reads (from `sys.dm_exec_query_stats`)
- Missing index suggestions (from `sys.dm_db_missing_index_*`)
- Index usage and unused indexes
- Index fragmentation

## Background

These patterns come from real problems I worked on in SQL Server stored procedures
in lending and data-management applications.

To start over, run `scripts/99_reset.sql`.
