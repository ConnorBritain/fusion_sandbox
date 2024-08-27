DECLARE @ParentTable NVARCHAR(128) = 'PAT';  -- Replace with your parent table name
DECLARE @ChildTable NVARCHAR(128) = 'RXF';   -- Replace with your child table name
DECLARE @ForeignKeyColumn NVARCHAR(128) = 'PAT_ID';  -- Replace with your foreign key column name

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT 
    ''' + @ChildTable + ''' AS ChildTable,
    ''' + @ParentTable + ''' AS ParentTable,
    ''' + @ForeignKeyColumn + ''' AS ForeignKeyColumn,
    COUNT(*) AS OrphanedRecordCount
FROM ' + @ChildTable + ' C
LEFT JOIN ' + @ParentTable + ' P ON C.' + @ForeignKeyColumn + ' = P.ID
WHERE P.ID IS NULL;'

EXEC sp_executesql @SQL;


--EXAMPLE:
/*
DECLARE @SQL NVARCHAR(MAX) = N'';

-- Check RXF (prescriptions) without corresponding PAT (patients)
SET @SQL = @SQL + N'
SELECT 
    ''RXF'' AS ChildTable,
    ''PAT'' AS ParentTable,
    ''PAT_ID'' AS ForeignKeyColumn,
    COUNT(*) AS OrphanedRecordCount
FROM RXF C
LEFT JOIN PAT P ON C.PAT_ID = P.ID
WHERE P.ID IS NULL;

';

-- Check FIL (fills) without corresponding RXF (prescriptions)
SET @SQL = @SQL + N'
SELECT 
    ''FIL'' AS ChildTable,
    ''RXF'' AS ParentTable,
    ''RXF_ID'' AS ForeignKeyColumn,
    COUNT(*) AS OrphanedRecordCount
FROM FIL C
LEFT JOIN RXF P ON C.RXF_ID = P.ID
WHERE P.ID IS NULL;

';

-- Check DRG_PHR (pharmacy-specific drug info) without corresponding DRG (drugs)
SET @SQL = @SQL + N'
SELECT 
    ''DRG_PHR'' AS ChildTable,
    ''DRG'' AS ParentTable,
    ''DRG_ID'' AS ForeignKeyColumn,
    COUNT(*) AS OrphanedRecordCount
FROM DRG_PHR C
LEFT JOIN DRG P ON C.DRG_ID = P.ID
WHERE P.ID IS NULL;

';

EXEC sp_executesql @SQL;
*/