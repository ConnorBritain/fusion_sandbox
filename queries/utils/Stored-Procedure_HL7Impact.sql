CREATE PROCEDURE TrackHL7Impact
    @WaitTimeSeconds INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Create and populate temporary table with initial counts
    CREATE TABLE #InitialCounts (
        TableName NVARCHAR(128),
        RecordCount INT
    );

    INSERT INTO #InitialCounts (TableName, RecordCount)
    EXEC sp_MSforeachtable 'SELECT ''?'' AS TableName, COUNT(*) AS RecordCount FROM ?';

    -- Wait for specified time (simulating HL7 processing)
    DECLARE @WaitString NVARCHAR(8) = RIGHT('00:00:0' + CAST(@WaitTimeSeconds AS NVARCHAR(2)), 8);
    WAITFOR DELAY @WaitString;

    -- Compare and show results
    SELECT 
        I.TableName,
        I.RecordCount AS InitialCount,
        CurrentCount.RecordCount AS CurrentCount,
        CurrentCount.RecordCount - I.RecordCount AS NewRecords
    FROM 
        #InitialCounts I
    CROSS APPLY (
        SELECT COUNT(*) AS RecordCount
        FROM sys.objects O
        CROSS APPLY (
            SELECT COUNT(*) AS RecordCount
            FROM [DBO].[' + I.TableName + ']
        ) AS CurrentCount
        WHERE O.name = I.TableName
    ) AS CurrentCount
    WHERE 
        CurrentCount.RecordCount - I.RecordCount > 0
    ORDER BY 
        NewRecords DESC;

    -- Clean up
    DROP TABLE #InitialCounts;
END

-- EXEC TrackHL7Impact @WaitTimeSeconds = 60; 
-- Adjust wait time as needed