SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS avg_seconds,
    qs.total_elapsed_time / 1000000.0 AS total_seconds,
    qs.execution_count,
    SUBSTRING(qt.text, qs.statement_start_offset/2 + 1,
        (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) AS individual_query,
    qt.text AS parent_query,
    DB_NAME(qt.dbid) AS database_name
FROM 
    sys.dm_exec_query_stats qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY 
    avg_seconds DESC;