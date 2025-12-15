--统计每个配电房（Substation）的高级别告警数量和平均处理时长（分钟）。
CREATE OR ALTER VIEW V_Alarm_HandlingEfficiency
AS
SELECT
    s.SubstationId,
    s.SubstationCode,
    s.Name AS SubstationName,
    COUNT(DISTINCT a.AlarmId) AS HighAlarmCount,
    AVG(DATEDIFF(MINUTE, w.DispatchTime, w.CompleteTime) * 1.0) AS AvgHandleMinutes
FROM Alarm a
JOIN WorkOrder w ON a.AlarmId = w.AlarmId
LEFT JOIN Substation s
    ON a.RelatedDeviceCode = s.SubstationCode
WHERE a.AlarmLevel = N'高'
GROUP BY s.SubstationId, s.SubstationCode, s.Name;
GO

--运维人员/管理员首页待办列表 + 告警总览仪表盘
CREATE OR ALTER VIEW V_Alarm_Unhandled_WithDeviceInfo
AS
SELECT
    a.AlarmId,
    a.AlarmType,
    a.AlarmLevel,
    a.Content,
    a.OccurTime,
    a.ProcessStatus,
    a.ThresholdDesc,
    DATEDIFF(MINUTE, a.OccurTime, SYSDATETIME()) AS UnhandledMinutes,

    ea.AssetName AS DeviceName,
    ea.EquipmentType,
    ea.ModelSpec,

    w.WorkOrderId,
    w.DispatchTime,
    w.ResponseTime,
    w.MaintainerId,
    u.UserName AS MaintainerName,

    CASE
        WHEN a.AlarmLevel = N'高'
             AND DATEDIFF(MINUTE, a.OccurTime, ISNULL(w.ResponseTime, SYSDATETIME())) > 15
            THEN N'响应超时'
        WHEN a.AlarmLevel = N'高' AND w.ResponseTime IS NOT NULL
            THEN N'已响应'
        ELSE N'待响应'
    END AS ResponseStatus
FROM Alarm a
LEFT JOIN EquipmentAsset ea
    ON a.RelatedDeviceCode = ea.RelatedDeviceCode
LEFT JOIN WorkOrder w ON a.AlarmId = w.AlarmId
LEFT JOIN UserAccount u ON w.MaintainerId = u.UserId
WHERE a.ProcessStatus IN (N'未处理', N'处理中');
GO


--质保到期前30天自动提醒（业务明确要求）
CREATE OR ALTER VIEW V_Equipment_WarrantyExpiry_Soon
AS
SELECT
    AssetId,
    AssetName,
    EquipmentType,
    ModelSpec,
    InstallTime,
    WarrantyYears,
    DATEADD(YEAR, WarrantyYears, InstallTime) AS WarrantyExpiryDate,
    DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) AS DaysToExpiry,
    CASE
        WHEN DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) <= 30
             AND DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) > 0
            THEN N'即将到期（30天内）'
        WHEN DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) <= 0
            THEN N'已到期'
        ELSE N'正常'
    END AS WarrantyStatus
FROM EquipmentAsset
WHERE ScrapStatus = N'正常使用'
  AND WarrantyYears IS NOT NULL
  AND InstallTime IS NOT NULL
  AND DATEADD(YEAR, WarrantyYears, InstallTime) <= DATEADD(DAY, 90, SYSDATETIME());
GO
