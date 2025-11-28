CREATE VIEW V_Pv_DailyGeneration
AS
SELECT
    gp.GridPointId,
    gp.GridPointCode,
    CAST(pg.CollectTime AS DATE) AS StatDate,
    SUM(pg.GenerationKWh) AS TotalGenerationKWh,
    SUM(pg.FeedInKWh) AS TotalFeedInKWh,
    SUM(pg.SelfUseKWh) AS TotalSelfUseKWh
FROM PvGeneration pg
JOIN PvDevice d ON pg.DeviceId = d.DeviceId
JOIN PvGridPoint gp ON pg.GridPointId = gp.GridPointId
GROUP BY gp.GridPointId, gp.GridPointCode, CAST(pg.CollectTime AS DATE);
GO

CREATE VIEW V_Pv_ForecastDeviation
AS
SELECT
    f.ForecastId,
    gp.GridPointCode,
    f.ForecastDate,
    f.TimeRange,
    f.ForecastGenerationKWh,
    f.ActualGenerationKWh,
    f.DeviationRate,
    CASE
        WHEN f.DeviationRate IS NOT NULL AND ABS(f.DeviationRate) > 15 THEN N'需优化'
        ELSE N'正常'
    END AS DeviationFlag
FROM PvForecast f
JOIN PvGridPoint gp ON f.GridPointId = gp.GridPointId;
GO