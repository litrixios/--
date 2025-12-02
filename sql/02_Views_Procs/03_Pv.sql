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

CREATE VIEW V_Pv_InverterEfficiencyAlert
AS
SELECT
    pg.DataId,
    d.DeviceId,
    d.DeviceCode,
    d.DeviceType,
    gp.GridPointId,
    gp.GridPointCode,
    gp.Name AS GridPointName,
    pg.CollectTime,
    CAST(pg.CollectTime AS DATE) AS StatDate,
    -- 效率数据
    pg.InverterEfficiency,
    pg.GenerationKWh,
    pg.FeedInKWh,
    pg.SelfUseKWh,
    pg.StringVoltageV,
    pg.StringCurrentA,
    -- 设备基础信息
    d.CapacityKWP,
    d.InstallLocation,
    d.RunStatus,
    -- 状态标记逻辑
    CASE
        WHEN pg.InverterEfficiency IS NULL THEN N'数据缺失'
        WHEN pg.InverterEfficiency < 85.00 THEN N'设备异常'
        ELSE N'运行正常'
    END AS EfficiencyStatus,
    -- 详细异常等级分类
    CASE
        WHEN pg.InverterEfficiency IS NULL THEN N'无效率数据'
        WHEN pg.InverterEfficiency < 70.00 THEN N'严重异常'
        WHEN pg.InverterEfficiency < 85.00 THEN N'一般异常'
        ELSE N'正常'
    END AS EfficiencyLevel
FROM PvGeneration pg
INNER JOIN PvDevice d ON pg.DeviceId = d.DeviceId
INNER JOIN PvGridPoint gp ON pg.GridPointId = gp.GridPointId
WHERE d.DeviceType = N'逆变器'  -- 只检查逆变器设备
    AND d.RunStatus = N'正常'   -- 只检查状态正常的设备
    AND pg.GenerationKWh > 0    -- 只检查有发电量的记录
    AND pg.CollectTime >= DATEADD(DAY, -7, GETDATE());  -- 最近7天的数据
GO