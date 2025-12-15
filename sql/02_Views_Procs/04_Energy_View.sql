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