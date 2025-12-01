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
        WHEN s.VoltageLevel = '35KV' AND cm.VoltageKV > 37 THEN N'电压越上限'
        WHEN s.VoltageLevel = '35KV' AND cm.VoltageKV < 33 THEN N'电压越下限'
        WHEN s.VoltageLevel = '0.4KV' AND cm.VoltageKV > 0.428 THEN N'电压越上限'
        WHEN s.VoltageLevel = '0.4KV' AND cm.VoltageKV < 0.372 THEN N'电压越下限'
        WHEN cm.CurrentA > 700 THEN N'电流越限'
        ELSE N'正常'
    END AS AbnormalReason
FROM CircuitMeasurement cm
JOIN Circuit c ON cm.CircuitId = c.CircuitId
JOIN Substation s ON cm.SubstationId = s.SubstationId
WHERE
    (cm.VoltageKV IS NULL OR cm.CurrentA IS NULL)
    OR (s.VoltageLevel = '35KV' AND (cm.VoltageKV > 37 OR cm.VoltageKV < 33))
    OR (s.VoltageLevel = '0.4KV' AND (cm.VoltageKV > 0.428 OR cm.VoltageKV < 0.372))
    OR (cm.CurrentA > 700);