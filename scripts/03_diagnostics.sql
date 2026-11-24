-- Diagnostic queries to find performance problems.
USE PerfLab;
GO

-- 1. Top 10 queries by total logical reads
SELECT TOP (10)
    qs.total_logical_reads,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_reads,
    qs.total_elapsed_time / qs.execution_count / 1000 AS avg_ms,
    SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_logical_reads DESC;

-- 2. Missing index suggestions (review them; don't create all of them blindly)
SELECT TOP (20)
    d.statement AS table_name,
    d.equality_columns, d.inequality_columns, d.included_columns,
    s.user_seeks, s.avg_user_impact,
    s.user_seeks * s.avg_total_user_cost * s.avg_user_impact AS score
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g ON g.index_handle = d.index_handle
JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle
WHERE d.database_id = DB_ID()
ORDER BY score DESC;

-- 3. Index usage: indexes that are written but never read are candidates to drop
SELECT OBJECT_NAME(i.object_id) AS table_name, i.name AS index_name,
       us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY us.user_updates DESC;

-- 4. Fragmentation
SELECT OBJECT_NAME(ps.object_id) AS table_name, i.name AS index_name,
       ps.avg_fragmentation_in_percent, ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.page_count > 100
ORDER BY ps.avg_fragmentation_in_percent DESC;
