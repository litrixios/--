CREATE PROCEDURE usp_CalcDailyPeakValleyEnergy
    @StatDate DATE,
    @EnergyType NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Cte AS (
        SELECT
            e.FactoryId,
            CASE
                WHEN CAST(e.CollectTime AS TIME) >= '10:00' AND CAST(e.CollectTime AS TIME) < '12:00'
                     OR CAST(e.CollectTime AS TIME) >= '16:00' AND CAST(e.CollectTime AS TIME) < '18:00'
                    THEN 'Sharp'
                WHEN CAST(e.CollectTime AS TIME) >= '08:00' AND CAST(e.CollectTime AS TIME) < '10:00'
                     OR CAST(e.CollectTime AS TIME) >= '12:00' AND CAST(e.CollectTime AS TIME) < '16:00'
                     OR CAST(e.CollectTime AS TIME) >= '18:00' AND CAST(e.CollectTime AS TIME) < '22:00'
                    THEN 'Peak'
                WHEN CAST(e.CollectTime AS TIME) >= '06:00' AND CAST(e.CollectTime AS TIME) < '08:00'
                     OR CAST(e.CollectTime AS TIME) >= '22:00'
                    THEN 'Flat'
                ELSE 'Valley' -- 00:00-06:00
            END AS PeriodType,
            e.Value
        FROM EnergyMeasurement e
        JOIN EnergyMeter m ON e.MeterId = m.MeterId
        WHERE m.EnergyType = @EnergyType
          AND CAST(e.CollectTime AS DATE) = @StatDate
    )
    MERGE PeakValleyEnergy AS tgt
    USING (
        SELECT
            FactoryId,
            SUM(CASE WHEN PeriodType = 'Sharp' THEN Value ELSE 0 END) AS SharpVal,
            SUM(CASE WHEN PeriodType = 'Peak' THEN Value ELSE 0 END) AS PeakVal,
            SUM(CASE WHEN PeriodType = 'Flat' THEN Value ELSE 0 END) AS FlatVal,
            SUM(CASE WHEN PeriodType = 'Valley' THEN Value ELSE 0 END) AS ValleyVal
        FROM Cte
        GROUP BY FactoryId
    ) AS src
    ON tgt.EnergyType = @EnergyType AND tgt.FactoryId = src.FactoryId AND tgt.StatDate = @StatDate
    WHEN MATCHED THEN
        UPDATE SET
            SharpPeriodValue = src.SharpVal,
            PeakPeriodValue = src.PeakVal,
            FlatPeriodValue = src.FlatVal,
            ValleyPeriodValue = src.ValleyVal,
            TotalValue = src.SharpVal + src.PeakVal + src.FlatVal + src.ValleyVal
    WHEN NOT MATCHED THEN
        INSERT (EnergyType, FactoryId, StatDate,
                SharpPeriodValue, PeakPeriodValue, FlatPeriodValue, ValleyPeriodValue, TotalValue)
        VALUES (@EnergyType, src.FactoryId, @StatDate,
                src.SharpVal, src.PeakVal, src.FlatVal, src.ValleyVal,
                src.SharpVal + src.PeakVal + src.FlatVal + src.ValleyVal);
END;
GO
