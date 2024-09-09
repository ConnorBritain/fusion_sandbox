--To identify Orphaned records, replace the values in the three variables below with your target tables/columns.

DECLARE @ParentTable NVARCHAR(128) = 'PAT' --'ParentTableName'
DECLARE @ChildTable NVARCHAR(128) = 'RXF'; --'ChildTableName'
DECLARE @ForeignKeyColumn NVARCHAR(128) = 'PAT_ID'; --'ForeignKeyColumnName'

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT C.*
FROM ' + @ChildTable + ' C
LEFT JOIN ' + @ParentTable + ' P ON C.' + @ForeignKeyColumn + ' = P.ID
WHERE P.ID IS NULL;'

EXEC sp_executesql @SQL;