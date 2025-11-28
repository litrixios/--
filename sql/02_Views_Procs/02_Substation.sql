CREATE VIEW V_Circuit_AbnormalData
AS
SELECT
    cm.DataId,
    s.SubstationCode,
    s.Name AS SubstationName,
    c.CircuitCode,
    cm.CollectTime,
    cm.VoltageKV,
    cm.CurrentA,
    CASE
        WHEN cm.VoltageKV IS NULL OR cm.CurrentA IS NULL THEN N'数据不完整'
        WHEN s.VoltageLevel = '35KV' AND cm.VoltageKV > 37 THEN N'电压越限'
        ELSE N'正常'
    END AS AbnormalReason
FROM CircuitMeasurement cm
JOIN Circuit c ON cm.CircuitId = c.CircuitId
JOIN Substation s ON cm.SubstationId = s.SubstationId
WHERE
    (cm.VoltageKV IS NULL OR cm.CurrentA IS NULL)
    OR (s.VoltageLevel = '35KV' AND cm.VoltageKV > 37);