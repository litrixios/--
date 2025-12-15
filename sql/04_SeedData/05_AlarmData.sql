-- ========= EquipmentAsset 测试数据 =========
-- 回路（Circuit）
INSERT INTO EquipmentAsset(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
VALUES
(N'主厂区1号主回路资产', N'回路', N'35kV/630A', '2020-01-10', 10, N'正常使用', 'CIR-SUB1-001'),
(N'办公楼供电回路资产', N'回路', N'35kV/400A', '2020-01-10', 10, N'正常使用', 'CIR-SUB1-002'),
(N'车间A1区回路资产', N'回路', N'0.4kV/800A', '2020-03-20', 8,  N'正常使用', 'CIR-SUB2-001'),
(N'光伏区主回路资产', N'回路', N'0.4kV/800A', '2022-07-01', 8,  N'正常使用', 'CIR-SUB4-001');

-- 变压器（Transformer）
INSERT INTO EquipmentAsset(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
VALUES
(N'1号主变资产', N'变压器', N'S13-1000kVA', '2020-01-20', 5, N'正常使用', 'TRA-SUB1-001'),
(N'车间A2变压器资产', N'变压器', N'S13-500kVA',  '2020-03-25', 5, N'正常使用', 'TRA-SUB2-002'),
(N'北厂辅助变压器资产', N'变压器', N'S13-400kVA',  '2021-06-01', 5, N'正常使用', 'TRA-SUB3-004'),
(N'光伏主变压器资产', N'变压器', N'S13-630kVA',  '2022-07-10', 5, N'正常使用', 'TRA-SUB4-001');

-- 光伏设备（PvDevice）
INSERT INTO EquipmentAsset(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
VALUES
(N'主厂区屋顶A区逆变器#1', N'逆变器', N'500kW-RS485', '2020-05-15', 8, N'正常使用', 'PV-DEV-001'),
(N'停车场光伏棚B区逆变器',   N'逆变器', N'400kW-RS485', '2020-06-20', 8, N'正常使用', 'PV-DEV-006'),
(N'北厂车间屋顶汇流箱',       N'汇流箱', N'60kW-Lora',   '2021-04-01', 6, N'正常使用', 'PV-DEV-011'),
(N'创新大厦屋顶逆变器',       N'逆变器', N'250kW-RS485', '2022-03-25', 8, N'正常使用', 'PV-DEV-024');

-- 能耗计量（EnergyMeter）
INSERT INTO EquipmentAsset(AssetName, EquipmentType, ModelSpec, InstallTime, WarrantyYears, ScrapStatus, RelatedDeviceCode)
VALUES
(N'主厂区总进线电表', N'电表', N'RS485-电',  '2020-01-05', 6, N'正常使用', 'EM-A01-001'),
(N'主厂区进水总管水表', N'水表', N'RS485-DN100', '2020-01-05', 6, N'正常使用', 'EM-A01-002'),
(N'北厂锅炉出口蒸汽表', N'蒸汽表', N'RS485-DN40', '2021-03-01', 6, N'正常使用', 'EM-A02-003'),
(N'能源基地调压站燃气表', N'燃气表', N'Lora-DN100', '2021-08-15', 6, N'正常使用', 'EM-A04-003');

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

-- ========= WorkOrder 补充测试数据 =========
-- 给“中/低告警”手工派发工单（触发器不会自动生成）
INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime, ResponseTime, CompleteTime, ResultDesc, ReviewStatus, AttachmentPath)
SELECT TOP 1 a.AlarmId, 4,
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
SELECT TOP 1 a.AlarmId, 4,
       DATEADD(MINUTE, 2, a.OccurTime),
       DATEADD(MINUTE, 6, a.OccurTime),
       DATEADD(MINUTE, 25, a.OccurTime),
       N'已复核保护定值，现场电流正常，告警为瞬时波动',
       N'通过',
       NULL
FROM Alarm a
WHERE a.AlarmLevel = N'低' AND a.RelatedDeviceCode = 'CIR-SUB2-001'
ORDER BY a.AlarmId DESC;
