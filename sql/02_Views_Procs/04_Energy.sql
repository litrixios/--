--基础日能耗汇总视图
CREATE VIEW V_Energy_DailyByFactory
AS
SELECT
    fa.FactoryId,
    fa.Name AS FactoryName,
    m.EnergyType,
    CAST(e.CollectTime AS DATE) AS StatDate,
    SUM(e.Value) AS TotalValue
FROM EnergyMeasurement e
JOIN EnergyMeter m ON e.MeterId = m.MeterId
JOIN FactoryArea fa ON e.FactoryId = fa.FactoryId
GROUP BY fa.FactoryId, fa.Name, m.EnergyType, CAST(e.CollectTime AS DATE);

GO
--高耗能厂区日统计视图
CREATE VIEW V_Energy_HighConsumption_FactoryDaily
AS
WITH Daily AS (
    SELECT
        fa.FactoryId,
        fa.Name AS FactoryName,
        m.EnergyType,
        CAST(e.CollectTime AS DATE) AS StatDate,
        SUM(e.Value) AS TotalValue
    FROM EnergyMeasurement e
    JOIN EnergyMeter m ON e.MeterId = m.MeterId
    JOIN FactoryArea fa ON e.FactoryId = fa.FactoryId
    -- 只统计数据质量较好的记录，避免异常值干扰
    WHERE e.DataQuality IN (N'优', N'良')
    GROUP BY
        fa.FactoryId,
        fa.Name,
        m.EnergyType,
        CAST(e.CollectTime AS DATE)
),
DailyWithAvg AS (
    SELECT
        d.*,
        -- 按 厂区 + 能源类型 计算历史平均日能耗
        AVG(d.TotalValue) OVER (
            PARTITION BY d.FactoryId, d.EnergyType
        ) AS AvgDailyValue
    FROM Daily d
)
SELECT
    FactoryId,
    FactoryName,
    EnergyType,
    StatDate,
    TotalValue,
    AvgDailyValue,
    -- 相对平均值的偏差百分比
    CASE
        WHEN AvgDailyValue IS NOT NULL AND AvgDailyValue <> 0
            THEN CAST((TotalValue - AvgDailyValue) * 100.0 / AvgDailyValue AS DECIMAL(5,2))
        ELSE NULL
    END AS ExceedPercent,   -- 超出百分比，单位：%
    CASE
        WHEN AvgDailyValue IS NOT NULL
             AND AvgDailyValue <> 0
             AND (TotalValue - AvgDailyValue) * 100.0 / AvgDailyValue >= 30
            THEN 1
        ELSE 0
    END AS IsHighConsumption -- 是否高耗能（超平均 30%）
FROM DailyWithAvg;
GO

--待核实能耗数据视图（数据质量中/差）,将数据质量为“中/差”或 NeedVerify=1 的记录集中出来，供能源管理员快速排查、核实，避免异常数据污染统计与报表。
CREATE VIEW V_Energy_MeasurementToVerify
AS
SELECT
    e.DataId,
    e.MeterId,
    m.MeterCode,
    m.EnergyType,
    e.CollectTime,
    e.Value,
    e.Unit,
    e.DataQuality,
    e.NeedVerify,
    e.FactoryId,
    fa.Name AS FactoryName,
    m.InstallLocation,
    m.PipeSpec,
    m.CommProtocol,
    m.RunStatus
FROM EnergyMeasurement e
JOIN EnergyMeter m ON e.MeterId = m.MeterId
JOIN FactoryArea fa ON e.FactoryId = fa.FactoryId
WHERE e.NeedVerify = 1
   OR e.DataQuality IN (N'中', N'差');

GO

--用于能源管理员的视图

CREATE VIEW V_Energy_Report AS
SELECT
    m.DataId,
    f.Name AS AreaName,      -- 改回英文
    em.MeterCode AS MeterCode,
    em.EnergyType AS EnergyType,
    m.CollectTime AS CollectTime,   -- 改回英文
    m.Value AS Value,
    m.Unit AS Unit,
    m.DataQuality AS Quality,
    m.NeedVerify AS NeedVerify
FROM EnergyMeasurement m
JOIN EnergyMeter em ON m.MeterId = em.MeterId
JOIN FactoryArea f ON m.FactoryId = f.FactoryId;
GO