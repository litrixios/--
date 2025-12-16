-- ========= EquipmentAsset 测试数据 =========
-- 回路（Circuit）
INSERT INTO EquipmentAsset
(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
SELECT
    CAST(c.Name + N'资产' AS NVARCHAR(50))                                         AS AssetName,
    N'回路'                                                                       AS EquipmentType,
    CAST(
        CONCAT(
            FORMAT(c.RatedVoltageKV, '0.##'), N'kV/',
            FORMAT(c.RatedCurrentA, '0.##'),  N'A'
        ) AS NVARCHAR(50)
    )                                                                             AS ModelSpec,
    -- 设备表里没装设日期：这里用“按站点+编码生成的伪日期”，确保可重复
    DATEADD(DAY, ABS(CHECKSUM(c.CircuitCode)) % 3650, '2018-01-01')               AS InstallTime,
    10                                                                            AS WarrantyYears,
    CASE WHEN ABS(CHECKSUM(c.CircuitCode)) % 100 < 6 THEN N'已报废' ELSE N'正常使用' END AS ScrapStatus,
    c.CircuitCode                                                                 AS RelatedDeviceCode
FROM Circuit c
WHERE NOT EXISTS (
    SELECT 1 FROM EquipmentAsset ea WHERE ea.RelatedDeviceCode = c.CircuitCode
);


-- 变压器（Transformer）
INSERT INTO EquipmentAsset
(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
SELECT
    CAST(t.Name + N'资产' AS NVARCHAR(50))                                         AS AssetName,
    N'变压器'                                                                     AS EquipmentType,
    CAST(CONCAT(N'S13-', FORMAT(t.CapacityKVA, '0.##'), N'kVA') AS NVARCHAR(50))   AS ModelSpec,
    t.InstallDate                                                                 AS InstallTime,
    5                                                                             AS WarrantyYears,
    CASE WHEN ABS(CHECKSUM(t.TransformerCode)) % 100 < 4 THEN N'已报废' ELSE N'正常使用' END AS ScrapStatus,
    t.TransformerCode                                                             AS RelatedDeviceCode
FROM Transformer t
WHERE NOT EXISTS (
    SELECT 1 FROM EquipmentAsset ea WHERE ea.RelatedDeviceCode = t.TransformerCode
);


-- 光伏设备（PvDevice）
INSERT INTO EquipmentAsset
(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
SELECT
    CAST(
        CASE
            WHEN p.DeviceType = N'逆变器' THEN CONCAT(p.InstallLocation, N'逆变器资产#', RIGHT(p.DeviceCode, 3))
            WHEN p.DeviceType = N'汇流箱' THEN CONCAT(p.InstallLocation, N'汇流箱资产#', RIGHT(p.DeviceCode, 3))
            ELSE CONCAT(p.InstallLocation, p.DeviceType, N'资产#', RIGHT(p.DeviceCode, 3))
        END
    AS NVARCHAR(50))                                                              AS AssetName,
    p.DeviceType                                                                  AS EquipmentType,
    CAST(CONCAT(FORMAT(p.CapacityKWP, '0.##'), N'kW-', p.CommProtocol) AS NVARCHAR(50)) AS ModelSpec,
    p.CommissionDate                                                              AS InstallTime,
    CASE
        WHEN p.DeviceType = N'逆变器' THEN 8
        WHEN p.DeviceType = N'汇流箱' THEN 6
        ELSE 6
    END                                                                           AS WarrantyYears,
    CASE WHEN ABS(CHECKSUM(p.DeviceCode)) % 100 < 5 THEN N'已报废' ELSE N'正常使用' END AS ScrapStatus,
    p.DeviceCode                                                                  AS RelatedDeviceCode
FROM PvDevice p
WHERE NOT EXISTS (
    SELECT 1 FROM EquipmentAsset ea WHERE ea.RelatedDeviceCode = p.DeviceCode
);


-- 能耗计量（EnergyMeter）
INSERT INTO EquipmentAsset
(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
SELECT
    CAST(CONCAT(m.InstallLocation, N'计量资产#', RIGHT(m.MeterCode, 3)) AS NVARCHAR(50)) AS AssetName,
    CASE m.EnergyType
        WHEN N'电'     THEN N'电表'
        WHEN N'水'     THEN N'水表'
        WHEN N'蒸汽'   THEN N'蒸汽表'
        WHEN N'天然气' THEN N'燃气表'
        ELSE CONCAT(m.EnergyType, N'表')
    END                                                                           AS EquipmentType,
    CAST(
        CONCAT(
            m.CommProtocol,
            CASE WHEN m.PipeSpec IS NULL OR LTRIM(RTRIM(m.PipeSpec)) = '' THEN '' ELSE CONCAT(N'-', m.PipeSpec) END
        ) AS NVARCHAR(50)
    )                                                                             AS ModelSpec,
    -- 表里没单独装设日期：按编码生成稳定伪日期
    DATEADD(DAY, ABS(CHECKSUM(m.MeterCode)) % 3650, '2018-01-01')                  AS InstallTime,
    6                                                                             AS WarrantyYears,
    CASE WHEN ABS(CHECKSUM(m.MeterCode)) % 100 < 3 THEN N'已报废' ELSE N'正常使用' END AS ScrapStatus,
    m.MeterCode                                                                   AS RelatedDeviceCode
FROM EnergyMeter m
WHERE NOT EXISTS (
    SELECT 1 FROM EquipmentAsset ea WHERE ea.RelatedDeviceCode = m.MeterCode
);


-- ========= Alarm 测试数据 =========
-- 注意：高告警会触发 TR_Alarm_CreateWorkOrder 自动插入工单，并将告警置为“处理中”
INSERT INTO Alarm(AlarmType, RelatedDeviceCode, OccurTime, AlarmLevel, Content, ProcessStatus, ThresholdDesc)
VALUES
(N'越限告警',  'TRA-SUB1-001', DATEADD(MINUTE, -120, SYSDATETIME()), N'高', N'1号主变温度超限，疑似散热异常', N'未处理', N'温度 > 95℃'),
(N'设备故障',  'PV-DEV-006',   DATEADD(MINUTE, -75,  SYSDATETIME()), N'高', N'停车场B区逆变器故障停机',     N'未处理', N'设备状态=故障'),
(N'通讯故障',  'EM-A04-003',   DATEADD(MINUTE, -40,  SYSDATETIME()), N'中', N'燃气表通讯中断',               N'未处理', N'连续5分钟无数据'),
(N'越限告警',  'CIR-SUB2-001', DATEADD(MINUTE, -30,  SYSDATETIME()), N'低', N'回路电流轻微越限',             N'未处理', N'电流 > 820A'),
(N'设备故障',  'TRA-SUB3-004', DATEADD(MINUTE, -20,  SYSDATETIME()), N'中', N'北厂辅助变压器状态异常告警',   N'未处理', N'状态=异常'),
(N'通讯故障',  'PV-DEV-011',   DATEADD(MINUTE, -10,  SYSDATETIME()), N'低', N'北厂汇流箱Lora链路不稳定',     N'未处理', N'丢包率>30%');
-- ========= Alarm 测试数据（补充至 25 条：新增 19 条）=========
INSERT INTO Alarm(AlarmType, RelatedDeviceCode, OccurTime, AlarmLevel, Content, ProcessStatus, ThresholdDesc)
VALUES
-- 7
(N'越限告警',  'TRA-SUB5-001', DATEADD(MINUTE, -180, SYSDATETIME()), N'高', N'能源基地主变1负载率持续过高',           N'未处理', N'负载率 > 90% 持续10分钟'),
-- 8
(N'越限告警',  'TRA-SUB6-001', DATEADD(MINUTE, -165, SYSDATETIME()), N'中', N'低压主变三相电流不平衡',               N'未处理', N'不平衡度 > 15%'),
-- 9
(N'设备故障',  'PV-DEV-024',   DATEADD(MINUTE, -155, SYSDATETIME()), N'高', N'创新大厦屋顶逆变器直流侧故障',         N'未处理', N'DC故障码=E-DC'),
-- 10
(N'通讯故障',  'PV-DEV-016',   DATEADD(MINUTE, -150, SYSDATETIME()), N'中', N'产业园B区逆变器通讯离线',             N'未处理', N'连续10分钟无心跳'),
-- 11
(N'越限告警',  'CIR-SUB6-001', DATEADD(MINUTE, -145, SYSDATETIME()), N'高', N'低压主回路电流严重越限，存在过载风险', N'未处理', N'电流 > 1100A'),
-- 12
(N'越限告警',  'CIR-SUB5-001', DATEADD(MINUTE, -140, SYSDATETIME()), N'中', N'能源基地主回路电压波动偏大',         N'未处理', N'电压波动 > ±8%'),
-- 13
(N'通讯故障',  'EM-A02-003',   DATEADD(MINUTE, -135, SYSDATETIME()), N'中', N'北厂蒸汽表通讯异常，疑似RS485干扰',   N'未处理', N'连续5分钟无数据'),
-- 14
(N'设备故障',  'TRA-SUB2-002', DATEADD(MINUTE, -130, SYSDATETIME()), N'中', N'车间A2变压器状态异常，需巡检确认',     N'未处理', N'状态=异常'),
-- 15
(N'越限告警',  'PV-DEV-012',   DATEADD(MINUTE, -125, SYSDATETIME()), N'低', N'产业园A区逆变器交流侧电压轻微越限',     N'未处理', N'AC电压 > 250V'),
-- 16
(N'通讯故障',  'PV-DEV-020',   DATEADD(MINUTE, -120, SYSDATETIME()), N'低', N'能源基地储能区汇流箱Lora信号偏弱',     N'未处理', N'信号强度 < -110dBm'),
-- 17
(N'越限告警',  'EM-A01-001',   DATEADD(MINUTE, -115, SYSDATETIME()), N'中', N'主厂区总进线电表功率因数偏低',         N'未处理', N'功率因数 < 0.85'),
-- 18
(N'越限告警',  'EM-A01-002',   DATEADD(MINUTE, -110, SYSDATETIME()), N'低', N'主厂区进水总管水表瞬时流量偏高',       N'未处理', N'流量 > 额定值120%'),
-- 19
(N'设备故障',  'PV-DEV-011',   DATEADD(MINUTE, -105, SYSDATETIME()), N'中', N'北厂汇流箱采集模块异常重启',           N'未处理', N'设备状态=故障'),
-- 20
(N'越限告警',  'CIR-SUB3-001', DATEADD(MINUTE, -100, SYSDATETIME()), N'中', N'北厂主回路电流接近上限',               N'未处理', N'电流 > 600A'),
-- 21
(N'通讯故障',  'EM-B01-003',   DATEADD(MINUTE, -95,  SYSDATETIME()), N'中', N'总部调压站燃气表Lora上报中断',         N'未处理', N'连续5分钟无数据'),
-- 22
(N'设备故障',  'TRA-SUB11-001',DATEADD(MINUTE, -90,  SYSDATETIME()), N'低', N'生态城配电房主变轻微告警：油温偏高',   N'未处理', N'油温 > 75℃'),
-- 23
(N'越限告警',  'PV-DEV-006',   DATEADD(MINUTE, -85,  SYSDATETIME()), N'中', N'停车场B区逆变器输出功率波动异常',       N'未处理', N'功率波动 > 30%'),
-- 24
(N'越限告警',  'TRA-SUB3-001', DATEADD(MINUTE, -80,  SYSDATETIME()), N'低', N'北厂主变负载率略高',                   N'未处理', N'负载率 > 80%'),
-- 25
(N'通讯故障',  'CIR-SUB4-002', DATEADD(MINUTE, -70,  SYSDATETIME()), N'低', N'光伏区备用回路监测终端数据上报延迟',   N'未处理', N'延迟 > 60秒');


-- ========= WorkOrder 补充测试数据 =========
-- 给“中/低告警”手工派发工单（触发器不会自动生成）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 6,
       DATEADD(MINUTE, 1, a.OccurTime),
       DATEADD(MINUTE, 8, a.OccurTime),
       DATEADD(MINUTE, 35, a.OccurTime),
       N'已检查通讯模块，重启后恢复，建议后续更换天线',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel = N'中' AND a.RelatedDeviceCode = 'EM-A04-003'
ORDER BY a.AlarmId DESC;

INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 6,
       DATEADD(MINUTE, 2, a.OccurTime),
       DATEADD(MINUTE, 6, a.OccurTime),
       DATEADD(MINUTE, 25, a.OccurTime),
       N'已复核保护定值，现场电流正常，告警为瞬时波动',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel = N'低' AND a.RelatedDeviceCode = 'CIR-SUB2-001'
ORDER BY a.AlarmId DESC;
-- ========= WorkOrder 补充测试数据（中/低告警再派 10 单；运维 6-13）=========

-- 1) MaintainerId = 6（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 6,
       DATEADD(MINUTE, 2,  a.OccurTime),
       DATEADD(MINUTE, 9,  a.OccurTime),
       DATEADD(MINUTE, 38, a.OccurTime),
       N'现场检查变压器风机运行正常，清理散热片积灰后温度回落，建议加强巡检频次',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'TRA-SUB6-001'
ORDER BY a.AlarmId DESC;

-- 2) MaintainerId = 6（低）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 6,
       DATEADD(MINUTE, 1,  a.OccurTime),
       DATEADD(MINUTE, 7,  a.OccurTime),
       DATEADD(MINUTE, 28, a.OccurTime),
       N'复核电压曲线，确认电压轻微波动来自上级母线切换，已记录并持续观察',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'PV-DEV-012'
ORDER BY a.AlarmId DESC;

-- 3) MaintainerId = 7（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 7,
       DATEADD(MINUTE, 3,  a.OccurTime),
       DATEADD(MINUTE, 10, a.OccurTime),
       DATEADD(MINUTE, 45, a.OccurTime),
       N'检查RS485接线与屏蔽层，重新压接端子后通讯恢复，建议对线路做绝缘测试',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'EM-A02-003'
ORDER BY a.AlarmId DESC;

-- 4) MaintainerId = 7（低）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 7,
       DATEADD(MINUTE, 2,  a.OccurTime),
       DATEADD(MINUTE, 6,  a.OccurTime),
       DATEADD(MINUTE, 30, a.OccurTime),
       N'检查Lora网关与终端信号，调整天线朝向并重启网关后上报恢复',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'PV-DEV-020'
ORDER BY a.AlarmId DESC;

-- 5) MaintainerId = 8（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 8,
       DATEADD(MINUTE, 4,  a.OccurTime),
       DATEADD(MINUTE, 12, a.OccurTime),
       DATEADD(MINUTE, 50, a.OccurTime),
       N'核查回路负载，建议错峰启停大功率设备；已在配电端记录电流峰值并提交分析',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'CIR-SUB3-001'
ORDER BY a.AlarmId DESC;

-- 6) MaintainerId = 9（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 9,
       DATEADD(MINUTE, 2,  a.OccurTime),
       DATEADD(MINUTE, 11, a.OccurTime),
       DATEADD(MINUTE, 44, a.OccurTime),
       N'检查功率因数与补偿柜投切，确认部分电容支路未投入，已恢复自动投切并观察稳定性',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'EM-A01-001'
ORDER BY a.AlarmId DESC;

-- 7) MaintainerId = 10（低）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 10,
       DATEADD(MINUTE, 1,  a.OccurTime),
       DATEADD(MINUTE, 5,  a.OccurTime),
       DATEADD(MINUTE, 22, a.OccurTime),
       N'核对水表瞬时流量与现场阀门状态，确认用水高峰导致，已记录峰值并建议分时用水',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'EM-A01-002'
ORDER BY a.AlarmId DESC;

-- 8) MaintainerId = 11（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 11,
       DATEADD(MINUTE, 3,  a.OccurTime),
       DATEADD(MINUTE, 9,  a.OccurTime),
       DATEADD(MINUTE, 36, a.OccurTime),
       N'检查逆变器通讯链路与交换机端口，发现端口自协商异常，重置端口后恢复在线',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'PV-DEV-016'
ORDER BY a.AlarmId DESC;

-- 9) MaintainerId = 12（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 12,
       DATEADD(MINUTE, 5,  a.OccurTime),
       DATEADD(MINUTE, 13, a.OccurTime),
       DATEADD(MINUTE, 55, a.OccurTime),
       N'复核三相电流与接线，确认负载分配不均；已建议调整单相负载并提交整改建议单',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'TRA-SUB6-001'
ORDER BY a.AlarmId DESC;

-- 10) MaintainerId = 13（中）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 13,
       DATEADD(MINUTE, 2,  a.OccurTime),
       DATEADD(MINUTE, 8,  a.OccurTime),
       DATEADD(MINUTE, 33, a.OccurTime),
       N'检查燃气表Lora链路与网关电源，恢复供电后数据补传正常，建议加装UPS避免掉电',
       N'未通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel IN (N'中', N'低') AND a.RelatedDeviceCode = 'EM-B01-003'
ORDER BY a.AlarmId DESC;


-- ========= 给尚无工单的 6 条报警补派“超24小时未响应”工单 =========
INSERT INTO WorkOrder
(
    AlarmId,
    MaintainerId,
    DispatchTime,
    ResponseTime,
    CompleteTime,
    ResultDesc,
    ReviewStatus,
    AttachmentPath
)
SELECT TOP (2)
    a.AlarmId,
    6 AS MaintainerId,  -- 统一指定一个运维人员，也可按需调整
    DATEADD(HOUR, -25, SYSDATETIME()) AS DispatchTime, -- 超出当前时间24小时
    NULL AS ResponseTime,
    NULL AS CompleteTime,
    NULL AS ResultDesc,
    N'未通过' AS ReviewStatus,
    NULL AS AttachmentPath
FROM Alarm a
WHERE NOT EXISTS (
    SELECT 1
    FROM WorkOrder w
    WHERE w.AlarmId = a.AlarmId
)
ORDER BY a.OccurTime ASC;

INSERT INTO WorkOrder
(
    AlarmId,
    MaintainerId,
    DispatchTime,
    ResponseTime,
    CompleteTime,
    ResultDesc,
    ReviewStatus,
    AttachmentPath
)
SELECT TOP (2)
    a.AlarmId,
    11 AS MaintainerId,  -- 统一指定一个运维人员，也可按需调整
    DATEADD(HOUR, -27, SYSDATETIME()) AS DispatchTime, -- 超出当前时间24小时
    NULL AS ResponseTime,
    NULL AS CompleteTime,
    NULL AS ResultDesc,
    N'未通过' AS ReviewStatus,
    NULL AS AttachmentPath
FROM Alarm a
WHERE NOT EXISTS (
    SELECT 1
    FROM WorkOrder w
    WHERE w.AlarmId = a.AlarmId
)
ORDER BY a.OccurTime ASC;

INSERT INTO WorkOrder
(
    AlarmId,
    MaintainerId,
    DispatchTime,
    ResponseTime,
    CompleteTime,
    ResultDesc,
    ReviewStatus,
    AttachmentPath
)
SELECT TOP (2)
    a.AlarmId,
    10 AS MaintainerId,  -- 统一指定一个运维人员，也可按需调整
    DATEADD(HOUR, -26, SYSDATETIME()) AS DispatchTime, -- 超出当前时间24小时
    NULL AS ResponseTime,
    NULL AS CompleteTime,
    NULL AS ResultDesc,
    N'未通过' AS ReviewStatus,
    NULL AS AttachmentPath
FROM Alarm a
WHERE NOT EXISTS (
    SELECT 1
    FROM WorkOrder w
    WHERE w.AlarmId = a.AlarmId
)
ORDER BY a.OccurTime ASC;


