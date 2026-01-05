INSERT INTO EnergyMeter (MeterCode, EnergyType, InstallLocation, PipeSpec, CommProtocol, RunStatus, CalibrationCycleMonths, Manufacturer, FactoryId)
VALUES
('EM-A01-001', N'电', N'主厂区总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 1),
('EM-A01-002', N'水', N'主厂区进水总管', 'DN100', 'RS485', N'正常', 24, N'宁波水表', 1),
('EM-A01-003', N'蒸汽', N'主厂区锅炉出口', 'DN50', 'RS485', N'正常', 12, N'上海自仪', 1),
('EM-A01-004', N'天然气', N'主厂区调压站', 'DN80', 'Lora', N'正常', 12, N'金卡智能', 1),
('EM-A02-001', N'电', N'北厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 2),
('EM-A02-002', N'水', N'北厂进水总管', 'DN80', 'RS485', N'正常', 24, N'宁波水表', 2),
('EM-A02-003', N'蒸汽', N'北厂锅炉出口', 'DN40', 'RS485', N'故障', 12, N'上海自仪', 2),
('EM-A03-001', N'电', N'光伏产业园总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 3),
('EM-A03-002', N'水', N'光伏产业园进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 3),
('EM-A04-001', N'电', N'能源基地总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 4),
('EM-A04-002', N'水', N'能源基地进水总管', 'DN100', 'RS485', N'正常', 24, N'宁波水表', 4),
('EM-A04-003', N'天然气', N'能源基地调压站', 'DN100', 'Lora', N'正常', 12, N'金卡智能', 4),
('EM-A05-001', N'电', N'化工园区总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 5),
('EM-A05-002', N'水', N'化工园区进水总管', 'DN80', 'RS485', N'正常', 24, N'宁波水表', 5),
('EM-A06-001', N'电', N'高新区总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 6),
('EM-A06-002', N'水', N'高新区进水总管', 'DN50', 'RS485', N'正常', 24, N'宁波水表', 6),
('EM-A07-002', N'水', N'空港工厂进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 7),
('EM-A07-003', N'蒸汽', N'空港工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 7),
('EM-A07-004', N'天然气', N'空港工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 7),
('EM-A08-003', N'蒸汽', N'临港工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 8),
('EM-A08-004', N'天然气', N'临港工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 8),
('EM-A09-001', N'电', N'生态城工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 9),
('EM-A09-002', N'水', N'生态城工厂进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 9),
('EM-A09-003', N'蒸汽', N'生态城工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 9),
('EM-A09-004', N'天然气', N'生态城工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 9),
('EM-A10-001', N'电', N'老城区工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 10),
('EM-A10-002', N'水', N'老城区工厂进水总管', 'DN50', 'RS485', N'正常', 24, N'宁波水表', 10),
('EM-A10-003', N'蒸汽', N'老城区工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 10),
('EM-A10-004', N'天然气', N'老城区工厂调压站', 'DN50', 'Lora', N'正常', 12, N'金卡智能', 10),
('EM-B01-001', N'电', N'总部总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 11),
('EM-B01-002', N'水', N'总部进水总管', 'DN100', 'RS485', N'正常', 24, N'宁波水表', 11),
('EM-B01-003', N'天然气', N'总部调压站', 'DN80', 'Lora', N'正常', 12, N'金卡智能', 11),
('EM-B02-002', N'水', N'生产基地进水总管', 'DN80', 'RS485', N'正常', 24, N'宁波水表', 12),
('EM-B02-003', N'蒸汽', N'生产基地锅炉出口', 'DN50', 'RS485', N'正常', 12, N'上海自仪', 12),
('EM-B02-004', N'天然气', N'生产基地调压站', 'DN80', 'Lora', N'正常', 12, N'金卡智能', 12),
('EM-B03-001', N'电', N'配套工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 13),
('EM-B03-002', N'水', N'配套工厂进水总管', 'DN50', 'RS485', N'正常', 24, N'宁波水表', 13),
('EM-B03-004', N'天然气', N'配套工厂调压站', 'DN50', 'Lora', N'正常', 12, N'金卡智能', 13),
('EM-B04-001', N'电', N'加工分厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 14),
('EM-B04-002', N'水', N'加工分厂进水总管', 'DN50', 'RS485', N'正常', 24, N'宁波水表', 14),
('EM-B04-003', N'蒸汽', N'加工分厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 14),
('EM-B04-004', N'天然气', N'加工分厂调压站', 'DN50', 'Lora', N'正常', 12, N'金卡智能', 14),
('EM-B05-002', N'水', N'组装工厂进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 15),
('EM-B05-003', N'蒸汽', N'组装工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 15),
('EM-B05-004', N'天然气', N'组装工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 15),
('EM-C01-001', N'电', N'沿海工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 16),
('EM-C02-002', N'水', N'内陆工厂进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 17),
('EM-C02-003', N'蒸汽', N'内陆工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 17),
('EM-C02-004', N'天然气', N'内陆工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 17),
('EM-C03-001', N'电', N'丘陵工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 18),
('EM-C03-002', N'水', N'丘陵工厂进水总管', 'DN50', 'RS485', N'正常', 24, N'宁波水表', 18),
('EM-C03-003', N'蒸汽', N'丘陵工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 18),
('EM-C03-004', N'天然气', N'丘陵工厂调压站', 'DN50', 'Lora', N'正常', 12, N'金卡智能', 18),
('EM-C04-001', N'电', N'平原工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 19),
('EM-C04-002', N'水', N'平原工厂进水总管', 'DN65', 'RS485', N'正常', 24, N'宁波水表', 19),
('EM-C04-003', N'蒸汽', N'平原工厂锅炉出口', 'DN40', 'RS485', N'正常', 12, N'上海自仪', 19),
('EM-C04-004', N'天然气', N'平原工厂调压站', 'DN65', 'Lora', N'正常', 12, N'金卡智能', 19),
('EM-C05-001', N'电', N'枢纽工厂总进线', NULL, 'RS485', N'正常', 12, N'华立仪表', 20),
('EM-C05-002', N'水', N'枢纽工厂进水总管', 'DN80', 'RS485', N'正常', 24, N'宁波水表', 20),
('EM-C05-003', N'蒸汽', N'枢纽工厂锅炉出口', 'DN50', 'RS485', N'正常', 12, N'上海自仪', 20),
('EM-C05-004', N'天然气', N'枢纽工厂调压站', 'DN80', 'Lora', N'正常', 12, N'金卡智能', 20);


SET NOCOUNT ON;
SET DATEFORMAT ymd;

DECLARE @StartDT DATETIME2(0) = '2025-01-01 00:00:00';
DECLARE @EndDT   DATETIME2(0) = '2025-11-28 23:00:00';  -- 含当天最后一小时

;WITH Hours AS (
    SELECT @StartDT AS CollectTime
    UNION ALL
    SELECT DATEADD(HOUR, 1, CollectTime)
    FROM Hours
    WHERE CollectTime < @EndDT
),
Meters AS (
    -- 只生成你要求的 4 个表：电1、水2、蒸汽3、天然气4
    SELECT *
    FROM (VALUES
        (1, N'kWh', N'电',     CAST(1200.0 AS FLOAT), CAST(180.0 AS FLOAT), 1), -- MeterId, Unit, Type, Base, Amp, FactoryId
        (2, N'm3',  N'水',     CAST(  24.0 AS FLOAT), CAST(  6.0 AS FLOAT), 1),
        (3, N't',   N'蒸汽',   CAST(   4.8 AS FLOAT), CAST(  1.6 AS FLOAT), 1),
        (4, N'm3',  N'天然气', CAST(  78.0 AS FLOAT), CAST( 18.0 AS FLOAT), 1)
    ) v(MeterId, Unit, EnergyType, BaseValue, AmpValue, FactoryId)
),
Src AS (
    SELECT
        m.MeterId,
        h.CollectTime,
        m.FactoryId,
        m.Unit,

        -- 生成一个“看起来像真实波动”的小时值（按日周期 + 周期叠加 + 缓慢趋势）
        CAST(
            m.BaseValue
            * (1.0 + (DATEDIFF(DAY, @StartDT, h.CollectTime) * 0.0008))  -- 缓慢上升趋势（可调）
            + m.AmpValue * (
                CASE
                    WHEN DATEPART(HOUR, h.CollectTime) BETWEEN 8 AND 20 THEN 1.0  -- 白天偏高
                    ELSE 0.6                                                     -- 夜间偏低
                END
              )
            + ((m.MeterId * 7 + DATEPART(HOUR, h.CollectTime) * 13 + DATEPART(DAYOFYEAR, h.CollectTime) * 3) % 17 - 8) * 0.25
            AS DECIMAL(18,3)
        ) AS Value,

        N'优' AS DataQuality,
        CAST(0 AS BIT) AS NeedVerify
    FROM Meters m
    CROSS JOIN Hours h
)
INSERT INTO EnergyMeasurement (MeterId, CollectTime, Value, Unit, DataQuality, FactoryId, NeedVerify)
SELECT
    s.MeterId, s.CollectTime, s.Value, s.Unit, s.DataQuality, s.FactoryId, s.NeedVerify
FROM Src s
WHERE NOT EXISTS (
    SELECT 1
    FROM EnergyMeasurement e
    WHERE e.MeterId = s.MeterId
      AND e.CollectTime = s.CollectTime
)
OPTION (MAXRECURSION 0);  -- 允许递归生成所有小时
GO

INSERT INTO EnergyMeasurement (MeterId, CollectTime, Value, Unit, DataQuality, FactoryId, NeedVerify)
VALUES
-- 设备5-6（电、水）
(5, '2025-11-28 17:00:00', 950.200, 'kWh', N'优', 2, 0),
(6, '2025-11-28 17:00:00', 18.500, 'm3', N'优', 2, 0),
-- 设备7（蒸汽，故障状态）
(7, '2025-11-28 17:00:00', 0.000, 't', N'差', 2, 1),
-- 设备8-9（电、水）
(8, '2025-11-28 17:00:00', 680.400, 'kWh', N'优', 3, 0),
(9, '2025-11-28 17:00:00', 15.200, 'm3', N'优', 3, 0),
-- 设备10-12（电、水、天然气）
(10, '2025-11-28 17:00:00', 1250.800, 'kWh', N'优', 4, 0),
(11, '2025-11-28 17:00:00', 32.500, 'm3', N'优', 4, 0),
(12, '2025-11-28 17:00:00', 120.300, 'm3', N'优', 4, 0),
-- 设备13-14（电、水）
(13, '2025-11-28 17:00:00', 850.600, 'kWh', N'优', 5, 0),
(14, '2025-11-28 17:00:00', 22.800, 'm3', N'优', 5, 0),
-- 设备15-16（电、水）
(15, '2025-11-28 17:00:00', 520.300, 'kWh', N'优', 6, 0),
(16, '2025-11-28 17:00:00', 12.500, 'm3', N'优', 6, 0),
-- 设备17-19（电、水、天然气）
(17, '2025-11-28 17:00:00', 1850.200, 'kWh', N'优', 11, 0),
(18, '2025-11-28 17:00:00', 45.600, 'm3', N'优', 11, 0),
(19, '2025-11-28 17:00:00', 95.800, 'm3', N'优', 11, 0),
-- 设备20（电）
(20, '2025-11-28 17:00:00', 780.500, 'kWh', N'优', 16, 0),
-- 新插入的设备21-56（从上面插入的设备，假设从MeterId=21开始）
-- 工厂7的设备21-23
(21, '2025-11-28 17:00:00', 14.800, 'm3', N'优', 7, 0),
(22, '2025-11-28 17:00:00', 3.200, 't', N'优', 7, 0),
(23, '2025-11-28 17:00:00', 45.600, 'm3', N'优', 7, 0),
-- 工厂8的设备24-25
(24, '2025-11-28 17:00:00', 2.800, 't', N'优', 8, 0),
(25, '2025-11-28 17:00:00', 38.900, 'm3', N'优', 8, 0),
-- 工厂9的设备26-29
(26, '2025-11-28 17:00:00', 420.300, 'kWh', N'优', 9, 0),
(27, '2025-11-28 17:00:00', 10.200, 'm3', N'优', 9, 0),
(28, '2025-11-28 17:00:00', 2.200, 't', N'优', 9, 0),
(29, '2025-11-28 17:00:00', 28.500, 'm3', N'优', 9, 0),
-- 工厂10的设备30-33
(30, '2025-11-28 17:00:00', 380.600, 'kWh', N'优', 10, 0),
(31, '2025-11-28 17:00:00', 9.800, 'm3', N'优', 10, 0),
(32, '2025-11-28 17:00:00', 1.900, 't', N'优', 10, 0),
(33, '2025-11-28 17:00:00', 25.300, 'm3', N'优', 10, 0),
-- 工厂12的设备34-36
(34, '2025-11-28 17:00:00', 11.500, 'm3', N'优', 12, 0),
(35, '2025-11-28 17:00:00', 2.500, 't', N'优', 12, 0),
(36, '2025-11-28 17:00:00', 42.800, 'm3', N'优', 12, 0),
-- 工厂13的设备37-39
(37, '2025-11-28 17:00:00', 320.400, 'kWh', N'优', 13, 0),
(38, '2025-11-28 17:00:00', 8.500, 'm3', N'优', 13, 0),
(39, '2025-11-28 17:00:00', 22.600, 'm3', N'优', 13, 0),
-- 工厂14的设备40-43
(40, '2025-11-28 17:00:00', 280.200, 'kWh', N'优', 14, 0),
(41, '2025-11-28 17:00:00', 7.800, 'm3', N'优', 14, 0),
(42, '2025-11-28 17:00:00', 1.600, 't', N'优', 14, 0),
(43, '2025-11-28 17:00:00', 20.800, 'm3', N'优', 14, 0),
-- 工厂15的设备44-46
(44, '2025-11-28 17:00:00', 6.500, 'm3', N'优', 15, 0),
(45, '2025-11-28 17:00:00', 1.400, 't', N'优', 15, 0),
(46, '2025-11-28 17:00:00', 18.200, 'm3', N'优', 15, 0),
-- 工厂17的设备47-49
(47, '2025-11-28 17:00:00', 8.200, 'm3', N'优', 17, 0),
(48, '2025-11-28 17:00:00', 1.800, 't', N'优', 17, 0),
(49, '2025-11-28 17:00:00', 26.500, 'm3', N'优', 17, 0),
-- 工厂18的设备50-53
(50, '2025-11-28 17:00:00', 250.800, 'kWh', N'优', 18, 0),
(51, '2025-11-28 17:00:00', 6.200, 'm3', N'优', 18, 0),
(52, '2025-11-28 17:00:00', 1.300, 't', N'优', 18, 0),
(53, '2025-11-28 17:00:00', 16.800, 'm3', N'优', 18, 0),
-- 工厂19的设备54-57
(54, '2025-11-28 17:00:00', 290.600, 'kWh', N'优', 19, 0),
(55, '2025-11-28 17:00:00', 7.500, 'm3', N'优', 19, 0),
(56, '2025-11-28 17:00:00', 1.500, 't', N'优', 19, 0),
(57, '2025-11-28 17:00:00', 23.200, 'm3', N'优', 19, 0),
-- 工厂20的设备58-61
(58, '2025-11-28 17:00:00', 520.300, 'kWh', N'优', 20, 0),
(59, '2025-11-28 17:00:00', 13.800, 'm3', N'优', 20, 0),
(60, '2025-11-28 17:00:00', 2.800, 't', N'优', 20, 0),
(61, '2025-11-28 17:00:00', 38.500, 'm3', N'优', 20, 0);

GO

-- 再插脏数据 (注意最后一条，我故意设为 NeedVerify = 1)
INSERT INTO EnergyMeasurement (MeterId, CollectTime, Value, Unit, DataQuality, FactoryId, NeedVerify) VALUES
(1, '2025-11-30 08:00:00', 120.5, 'kWh', '优', 1, 0), -- 正常
(1, '2025-11-30 09:00:00', 130.2, 'kWh', '优', 1, 0), -- 正常
(1, '2025-11-30 10:00:00', 9999.9, 'kWh', '差', 1, 1); -- 异常数据！待核实！

GO
SET NOCOUNT ON;
SET DATEFORMAT ymd;

-- =============================================
-- 自动生成最近 1 年（今天 + 前 1 年）的峰谷能耗统计数据
-- 插入表：PeakValleyEnergy
-- =============================================

DECLARE @Today DATE = CAST(GETDATE() AS DATE);             -- 今天
DECLARE @StartDate DATE = DATEADD(YEAR, -1, @Today);       -- 前 1 年（包含）
DECLARE @EndDate   DATE = @Today;                          -- 今天（包含）

;WITH Dates AS (
    -- 递归生成连续日期
    SELECT @StartDate AS StatDate
    UNION ALL
    SELECT DATEADD(DAY, 1, StatDate)
    FROM Dates
    WHERE StatDate < @EndDate
),
-- 20个厂区的日基准能耗量（可根据实际情况调整）
Factories AS (
    SELECT *
    FROM (VALUES
        (1 , 46000.0, 260.0, 55.0,  90.0),  -- FactoryId, 电(kWh), 水(m?), 蒸汽(t), 天然气(m?)
        (2 , 24000.0, 180.0, 40.0,  60.0),
        (3 , 18000.0, 150.0,  0.0,   0.0),
        (4 , 28000.0, 210.0,  0.0,  75.0),
        (5 , 22000.0, 190.0,  0.0,   0.0),
        (6 , 15000.0, 120.0,  0.0,   0.0),
        (7 ,     0.0, 140.0, 32.0,  46.0),
        (8 ,     0.0,   0.0, 28.0,  39.0),
        (9 , 12000.0, 100.0, 22.0,  29.0),
        (10, 11000.0,  95.0, 19.0,  26.0),
        (11, 30000.0, 230.0,  0.0,  70.0),
        (12,     0.0, 170.0, 25.0,  43.0),
        (13,  9000.0,  85.0,  0.0,  23.0),
        (14,  8000.0,  78.0, 16.0,  21.0),
        (15,     0.0,  70.0, 14.0,  18.0),
        (16, 14000.0,   0.0,  0.0,   0.0),
        (17,     0.0,  88.0, 18.0,  27.0),
        (18,  7000.0,  62.0, 13.0,  17.0),
        (19,  8200.0,  75.0, 15.0,  23.0),
        (20, 16000.0, 105.0, 28.0,  38.0)
    ) AS v(FactoryId, ElecBase, WaterBase, SteamBase, GasBase)
),
-- 将四个能源类型展开
EnergyExpand AS (
    SELECT FactoryId, N'电'     AS EnergyType, ElecBase   AS BaseValue, 0.8500    AS UnitPrice FROM Factories WHERE ElecBase  > 0
    UNION ALL
    SELECT FactoryId, N'水'     AS EnergyType, WaterBase  AS BaseValue, 3.2000    AS UnitPrice FROM Factories WHERE WaterBase > 0
    UNION ALL
    SELECT FactoryId, N'蒸汽'   AS EnergyType, SteamBase  AS BaseValue, 210.0000  AS UnitPrice FROM Factories WHERE SteamBase > 0
    UNION ALL
    SELECT FactoryId, N'天然气' AS EnergyType, GasBase    AS BaseValue, 2.6000    AS UnitPrice FROM Factories WHERE GasBase   > 0
),
-- 主计算逻辑
Src AS (
    SELECT
        e.EnergyType,
        e.FactoryId,
        d.StatDate,
        e.UnitPrice AS PeakValleyPrice,
        -- 当天总量 = 基准量 × (1 + 随天增长2%) × (厂区固定扰动 ±3%)
        e.BaseValue
            * (1.0 + DATEDIFF(DAY, @StartDate, d.StatDate) * 0.02)
            * (1.0 + ((e.FactoryId % 7) - 3) * 0.01) AS TotalValue
    FROM EnergyExpand e
    CROSS JOIN Dates d
)
-- 最终插入 PeakValleyEnergy
INSERT INTO PeakValleyEnergy (
    EnergyType, FactoryId, StatDate,
    SharpPeriodValue, PeakPeriodValue, FlatPeriodValue, ValleyPeriodValue,
    TotalValue, PeakValleyPrice, EnergyCost
)
SELECT
    EnergyType,
    FactoryId,
    StatDate,

    ROUND(TotalValue * 0.12, 3) AS SharpPeriodValue,  -- 尖峰段 12%
    ROUND(TotalValue * 0.38, 3) AS PeakPeriodValue,   -- 峰段   38%
    ROUND(TotalValue * 0.32, 3) AS FlatPeriodValue,   -- 平段   32%
    ROUND(TotalValue * 0.18, 3) AS ValleyPeriodValue, -- 谷段   18%

    ROUND(TotalValue, 3)                    AS TotalValue,
    PeakValleyPrice,
    ROUND(TotalValue * PeakValleyPrice, 2) AS EnergyCost
FROM Src s
WHERE NOT EXISTS (  -- 防重插
    SELECT 1
    FROM PeakValleyEnergy p
    WHERE p.EnergyType = s.EnergyType
      AND p.FactoryId  = s.FactoryId
      AND p.StatDate   = s.StatDate
)
ORDER BY StatDate DESC, FactoryId, EnergyType
OPTION (MAXRECURSION 400);



-- 插入测试数据到电价政策表
INSERT INTO ElectricityPricePolicy (TimeStart, PriceType) VALUES
('00:00', 'Valley'), -- 深夜低谷
('08:00', 'Peak'),   -- 早高峰
('12:00', 'Flat'),   -- 中午平段
('14:00', 'Peak'),   -- 下午高峰
('18:00', 'Sharp'),  -- 傍晚尖峰
('22:00', 'Flat');   -- 晚间平段