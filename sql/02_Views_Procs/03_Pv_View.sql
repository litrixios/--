--光伏日发电量统计视图，统计每个光伏电网点每日的发电总量、上网电量和自用电量
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
-- 光伏预测偏差分析视图，展示光伏发电预测与实际发电的偏差情况，并进行预警标记
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
--逆变器效率预警视图，监控逆变器运行效率，识别效率异常设备并分级预警
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


CREATE VIEW V_Pv_ForecastDeviationAnalysis AS
-- 使用CTE（公共表表达式）进行分步数据处理
WITH DeviceData AS (
    -- 获取每个设备的基础数据
    SELECT
        gp.GridPointId,
        gp.GridPointCode,
        gp.Name AS GridPointName,
        gp.Location,
        -- 设备最早数据时间
        MIN(f.ForecastDate) AS FirstRecordDate,
        -- 设备最晚数据时间
        MAX(f.ForecastDate) AS LastRecordDate,
        -- 总记录数
        COUNT(*) AS TotalRecords,
        -- 总预测发电量
        SUM(f.ForecastGenerationKWh) AS TotalForecastKWh,
        -- 总实际发电量
        SUM(f.ActualGenerationKWh) AS TotalActualKWh,
        -- 平均偏差率
        AVG(f.DeviationRate) AS AvgDeviationRate,
        -- 最大偏差率
        MAX(f.DeviationRate) AS MaxDeviationRate,
        -- 最小偏差率
        MIN(f.DeviationRate) AS MinDeviationRate,
        -- 高偏差记录数（偏差率>15%）
        SUM(CASE WHEN f.DeviationRate > 15 THEN 1 ELSE 0 END) AS HighDeviationCount,
        -- 高偏差记录比例
        CAST(SUM(CASE WHEN f.DeviationRate > 15 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS HighDeviationRate,
        -- 是否有优化需求
        MAX(CONVERT(INT, f.NeedModelOptimize)) AS HasOptimizationNeed
    FROM PvGridPoint gp
    INNER JOIN PvForecast f ON gp.GridPointId = f.GridPointId
    WHERE f.ActualGenerationKWh IS NOT NULL
    GROUP BY gp.GridPointId, gp.GridPointCode, gp.Name, gp.Location
),
DailyDeviation AS (
    -- 计算每日偏差情况，用于连续高偏差分析
    SELECT
        gp.GridPointId,
        f.ForecastDate,
        -- 每日平均偏差率
        AVG(f.DeviationRate) AS DailyDeviationRate,
        -- 标记是否为高偏差日
        CASE WHEN AVG(f.DeviationRate) > 15 THEN 1 ELSE 0 END AS IsHighDeviationDay
    FROM PvGridPoint gp
    INNER JOIN PvForecast f ON gp.GridPointId = f.GridPointId
    WHERE f.ActualGenerationKWh IS NOT NULL
    GROUP BY gp.GridPointId, f.ForecastDate
),
DeviationGroups AS (
    -- 计算连续高偏差天数
    SELECT
        GridPointId,
        ForecastDate,
        DailyDeviationRate,
        IsHighDeviationDay,
        -- 为连续的高偏差日分组
        SUM(CASE WHEN IsHighDeviationDay = 0 THEN 1 ELSE 0 END)
            OVER (PARTITION BY GridPointId ORDER BY ForecastDate) AS GroupId
    FROM DailyDeviation
),
ConsecutiveAnalysis AS (
    -- 计算每组连续高偏差的天数
    SELECT
        GridPointId,
        ForecastDate,
        DailyDeviationRate,
        IsHighDeviationDay,
        GroupId,
        -- 计算连续高偏差天数
        COUNT(CASE WHEN IsHighDeviationDay = 1 THEN 1 END)
            OVER (PARTITION BY GridPointId, GroupId ORDER BY ForecastDate
                  ROWS UNBOUNDED PRECEDING) AS ConsecutiveDays
    FROM DeviationGroups
),
MaxConsecutive AS (
    -- 获取每个设备的最大连续高偏差天数
    SELECT
        GridPointId,
        MAX(ConsecutiveDays) AS MaxConsecutiveHighDeviationDays
    FROM ConsecutiveAnalysis
    WHERE IsHighDeviationDay = 1
    GROUP BY GridPointId
),
FinalAnalysis AS (
    -- 合并所有分析数据
    SELECT
        dd.GridPointId,
        dd.GridPointCode,
        dd.GridPointName,
        dd.Location,
        dd.FirstRecordDate,
        dd.LastRecordDate,
        dd.TotalRecords,
        dd.TotalForecastKWh,
        dd.TotalActualKWh,
        dd.AvgDeviationRate,
        dd.MaxDeviationRate,
        dd.MinDeviationRate,
        dd.HighDeviationCount,
        dd.HighDeviationRate,
        dd.HasOptimizationNeed,
        ISNULL(mc.MaxConsecutiveHighDeviationDays, 0) AS MaxConsecutiveHighDeviationDays,
        -- 计算发电完成率
        CASE
            WHEN dd.TotalForecastKWh > 0 THEN
                (dd.TotalActualKWh / dd.TotalForecastKWh) * 100
            ELSE NULL
        END AS CompletionRate,
        -- 计算数据覆盖天数
        DATEDIFF(DAY, dd.FirstRecordDate, dd.LastRecordDate) + 1 AS DataCoverageDays,
        -- 计算数据完整率
        CAST(dd.TotalRecords AS FLOAT) /
        (DATEDIFF(DAY, dd.FirstRecordDate, dd.LastRecordDate) + 1) *
        (SELECT COUNT(DISTINCT TimeRange) FROM PvForecast) AS DataCompletenessRate
    FROM DeviceData dd
    LEFT JOIN MaxConsecutive mc ON dd.GridPointId = mc.GridPointId
)
-- 最终视图输出
SELECT
    GridPointCode AS 设备编码,
    GridPointName AS 设备名称,
    Location AS 位置,
    FirstRecordDate AS 开始时间,
    LastRecordDate AS 结束时间,
    TotalRecords AS 总记录数,
    DataCoverageDays AS 数据覆盖天数,
    DataCompletenessRate AS 数据完整率,
    TotalForecastKWh AS 总预测发电量,
    TotalActualKWh AS 总实际发电量,
    CompletionRate AS 发电完成率,
    AvgDeviationRate AS 平均偏差率,
    MaxDeviationRate AS 最大偏差率,
    MinDeviationRate AS 最小偏差率,
    HighDeviationCount AS 高偏差次数,
    HighDeviationRate AS 高偏差比例,
    MaxConsecutiveHighDeviationDays AS 最大连续高偏差天数,
    -- 生成优化建议
    CASE
        WHEN MaxConsecutiveHighDeviationDays >= 3 THEN N'建议优化'
        WHEN HighDeviationRate > 30 THEN N'关注'  -- 高偏差比例超过30%时关注
        ELSE N'正常'
    END AS 优化建议
FROM FinalAnalysis;
GO