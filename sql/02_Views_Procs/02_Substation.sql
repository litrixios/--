--回路异常视图
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

GO
--变压器异常视图
CREATE VIEW V_Transformer_AbnormalData
AS
SELECT
    tm.DataId,
    s.SubstationCode,
    s.Name AS SubstationName,
    t.TransformerCode,
    tm.CollectTime,
    tm.LoadRate,
    tm.WindingTemp,
    tm.CoreTemp,
    tm.EnvTemp,
    tm.EnvHumidity,
    tm.RunStatus,
    CASE
        WHEN tm.LoadRate IS NULL
          OR tm.WindingTemp IS NULL
          OR tm.CoreTemp IS NULL THEN N'数据不完整'
        WHEN tm.RunStatus = N'异常'
          OR t.Status = N'异常' THEN N'运行异常'
        ELSE N'正常'
    END AS AbnormalReason
FROM TransformerMeasurement tm
JOIN Transformer t ON tm.TransformerId = t.TransformerId
JOIN Substation s ON tm.SubstationId = s.SubstationId
WHERE
      tm.LoadRate IS NULL
   OR tm.WindingTemp IS NULL
   OR tm.CoreTemp IS NULL
   OR tm.RunStatus = N'异常'
   OR t.Status = N'异常';

GO

-- substation操作总览视图
CREATE VIEW V_Substation_OperationOverview
AS
WITH LatestCircuitTime AS (
    SELECT
        SubstationId,
        MAX(CollectTime) AS LatestCircuitCollectTime
    FROM CircuitMeasurement
    GROUP BY SubstationId
),
LatestTransformerTime AS (
    SELECT
        SubstationId,
        MAX(CollectTime) AS LatestTransformerCollectTime
    FROM TransformerMeasurement
    GROUP BY SubstationId
),
CircuitAbnCount AS (
    SELECT
        s.SubstationId,
        COUNT(1) AS CircuitAbnormalCount
    FROM V_Circuit_AbnormalData v
    JOIN Substation s ON v.SubstationCode = s.SubstationCode
    GROUP BY s.SubstationId
),
TransformerAbnCount AS (
    SELECT
        s.SubstationId,
        COUNT(1) AS TransformerAbnormalCount
    FROM V_Transformer_AbnormalData v
    JOIN Substation s ON v.SubstationCode = s.SubstationCode
    GROUP BY s.SubstationId
)
SELECT
    s.SubstationId,
    s.SubstationCode,
    s.Name AS SubstationName,
    s.LocationDesc,
    s.VoltageLevel,
    s.TransformerCount,
    s.CommissionDate,
    s.ResponsibleUserId,
    s.ContactPhone,

    -- 设备数量
    (SELECT COUNT(1) FROM Circuit c WHERE c.SubstationId = s.SubstationId) AS CircuitCount,
    (SELECT COUNT(1) FROM Transformer t WHERE t.SubstationId = s.SubstationId) AS TransformerDeviceCount,

    -- 异常统计
    ISNULL(cac.CircuitAbnormalCount, 0) AS CircuitAbnormalCount,
    ISNULL(tac.TransformerAbnormalCount, 0) AS TransformerAbnormalCount,

    -- 最近采集时间
    lct.LatestCircuitCollectTime,
    ltt.LatestTransformerCollectTime,

    -- 总体状态（有任一异常则异常）
    CASE
        WHEN ISNULL(cac.CircuitAbnormalCount,0) > 0
          OR ISNULL(tac.TransformerAbnormalCount,0) > 0 THEN N'异常'
        ELSE N'正常'
    END AS OperationStatus
FROM Substation s
LEFT JOIN LatestCircuitTime lct ON s.SubstationId = lct.SubstationId
LEFT JOIN LatestTransformerTime ltt ON s.SubstationId = ltt.SubstationId
LEFT JOIN CircuitAbnCount cac ON s.SubstationId = cac.SubstationId
LEFT JOIN TransformerAbnCount tac ON s.SubstationId = tac.SubstationId;

