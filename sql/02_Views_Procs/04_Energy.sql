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