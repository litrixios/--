-- 配电房高级别告警处理效率统计视图
-- 功能：统计每个配电房的高级别告警数量及平均处理时长，用于监控各配电房告警处理效率
CREATE OR ALTER VIEW V_Alarm_Transformer
AS
SELECT
    a.AlarmId,
    t.TransformerCode,
    wo.DispatchTime,
    e.AssetName,
    e.EquipmentType,
    a.Content,
    a.ThresholdDesc
FROM WorkOrder wo
INNER JOIN Alarm a ON a.AlarmId=wo.AlarmId
INNER JOIN EquipmentAsset e ON a.RelatedDeviceCode=e.RelatedDeviceCode
INNER JOIN Transformer t ON e.RelatedDeviceCode=t.TransformerCode
WHERE a.AlarmLevel=N'高'
GO

CREATE OR ALTER VIEW V_Alarm_PvDevice
AS
SELECT
    a.AlarmId,
    t.DeviceCode,
    wo.DispatchTime,
    e.AssetName,
    e.EquipmentType,
    a.Content,
    a.ThresholdDesc
FROM WorkOrder wo
INNER JOIN Alarm a ON a.AlarmId=wo.AlarmId
INNER JOIN EquipmentAsset e ON a.RelatedDeviceCode=e.RelatedDeviceCode
INNER JOIN PvDevice t ON e.RelatedDeviceCode=t.DeviceCode
WHERE a.AlarmLevel=N'高'
GO

CREATE OR ALTER VIEW V_Alarm_EnergyMeter
AS
SELECT
    a.AlarmId,
    t.MeterCode,
    wo.DispatchTime,
    e.AssetName,
    e.EquipmentType,
    a.Content,
    a.ThresholdDesc
FROM WorkOrder wo
INNER JOIN Alarm a ON a.AlarmId=wo.AlarmId
INNER JOIN EquipmentAsset e ON a.RelatedDeviceCode=e.RelatedDeviceCode
INNER JOIN EnergyMeter t ON e.RelatedDeviceCode=t.MeterCode
WHERE a.AlarmLevel=N'高'
GO

CREATE OR ALTER VIEW V_Alarm_Circuit
AS
SELECT
    a.AlarmId,
    t.CircuitCode,
    wo.DispatchTime,
    e.AssetName,
    e.EquipmentType,
    a.Content,
    a.ThresholdDesc
FROM WorkOrder wo
INNER JOIN Alarm a ON a.AlarmId=wo.AlarmId
INNER JOIN EquipmentAsset e ON a.RelatedDeviceCode=e.RelatedDeviceCode
INNER JOIN Circuit t ON e.RelatedDeviceCode=t.CircuitCode
WHERE a.AlarmLevel=N'高'
GO

CREATE OR ALTER VIEW V_Alarm_EnergyMeter
AS
SELECT
    a.AlarmId,
    t.MeterCode,
    wo.DispatchTime,
    e.AssetName,
    e.EquipmentType,
    a.Content,
    a.ThresholdDesc
FROM WorkOrder wo
INNER JOIN Alarm a ON a.AlarmId=wo.AlarmId
INNER JOIN EquipmentAsset e ON a.RelatedDeviceCode=e.RelatedDeviceCode
INNER JOIN EnergyMeter t ON e.RelatedDeviceCode=t.MeterCode
WHERE a.AlarmLevel=N'高'
GO
-- 运维人员/管理员首页待办列表 + 告警总览仪表盘视图
-- 功能：展示未处理告警的详细信息及处理状态，用于首页待办列表和仪表盘展示
CREATE OR ALTER VIEW V_Alarm_Unhandled_WithDeviceInfo
AS
SELECT
    a.AlarmId,                          -- 告警ID
    a.AlarmType,                        -- 告警类型
    a.AlarmLevel,                       -- 告警级别
    a.Content,                          -- 告警内容
    a.OccurTime,                        -- 告警发生时间
    a.ProcessStatus,                    -- 处理状态
    a.ThresholdDesc,                    -- 阈值描述
    DATEDIFF(MINUTE, a.OccurTime, SYSDATETIME()) AS UnhandledMinutes,  -- 未处理时长（分钟）

    ea.AssetName AS DeviceName,         -- 设备名称
    ea.EquipmentType,                   -- 设备类型
    ea.ModelSpec,                       -- 设备型号规格

    w.WorkOrderId,                      -- 工单ID
    w.DispatchTime,                     -- 工单派发时间
    w.ResponseTime,                     -- 工单响应时间
    w.MaintainerId,                     -- 维护人员ID
    u.UserName AS MaintainerName,       -- 维护人员姓名

    -- 响应状态判定逻辑：
    -- 1. 高级别告警且（当前无响应时间且超过15分钟）或（有响应时间但已超时）：标记为'响应超时'
    -- 2. 高级别告警已有响应：标记为'已响应'
    -- 3. 其他情况：标记为'待响应'
    CASE
        WHEN a.AlarmLevel = N'高'
             AND DATEDIFF(MINUTE, a.OccurTime, ISNULL(w.ResponseTime, SYSDATETIME())) > 15
            THEN N'响应超时'
        WHEN a.AlarmLevel = N'高' AND w.ResponseTime IS NOT NULL
            THEN N'已响应'
        ELSE N'待响应'
    END AS ResponseStatus
FROM Alarm a                            -- 告警表
LEFT JOIN EquipmentAsset ea
    ON a.RelatedDeviceCode = ea.RelatedDeviceCode  -- 关联设备资产表，获取设备信息
LEFT JOIN WorkOrder w ON a.AlarmId = w.AlarmId     -- 关联工单表，获取工单信息
LEFT JOIN UserAccount u ON w.MaintainerId = u.UserId  -- 关联用户表，获取维护人员信息
WHERE a.ProcessStatus IN (N'未处理', N'处理中');  -- 只查询未处理和处理中的告警
GO

-- 设备质保到期预警视图（业务明确要求：到期前30天自动提醒）
-- 功能：监控设备质保到期情况，提前30天预警
CREATE OR ALTER VIEW V_Equipment_WarrantyExpiry_Soon
AS
SELECT
    AssetId,                            -- 资产ID
    AssetName,                          -- 资产名称
    EquipmentType,                      -- 设备类型
    ModelSpec,                          -- 型号规格
    InstallTime,                        -- 安装时间
    WarrantyYears,                      -- 质保年数
    DATEADD(YEAR, WarrantyYears, InstallTime) AS WarrantyExpiryDate,  -- 质保到期日期（安装时间+质保年数）
    DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) AS DaysToExpiry,  -- 距离到期剩余天数
    -- 质保状态判定逻辑：
    -- 1. 30天内到期：标记为'即将到期（30天内）'
    -- 2. 已到期：标记为'已到期'
    -- 3. 其他：标记为'正常'
    CASE
        WHEN DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) <= 30
             AND DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) > 0
            THEN N'即将到期（30天内）'
        WHEN DATEDIFF(DAY, SYSDATETIME(), DATEADD(YEAR, WarrantyYears, InstallTime)) <= 0
            THEN N'已到期'
        ELSE N'正常'
    END AS WarrantyStatus
FROM EquipmentAsset
WHERE ScrapStatus = N'正常使用'         -- 只统计正常使用的设备
  AND WarrantyYears IS NOT NULL         -- 质保年数不为空
  AND InstallTime IS NOT NULL           -- 安装时间不为空
  AND DATEADD(YEAR, WarrantyYears, InstallTime) <= DATEADD(DAY, 90, SYSDATETIME());  -- 只查询90天内到期的设备
GO