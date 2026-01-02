-- =============================================
-- 0) 清理（按需）
-- =============================================
TRUNCATE TABLE dbo.HistoryTrend;
TRUNCATE TABLE dbo.RealtimeSummary;
TRUNCATE TABLE dbo.DashboardConfig;
GO

-- =============================================
-- 1) DashboardConfig 扩充
-- =============================================
INSERT INTO DashboardConfig (ModuleCode, RefreshIntervalSeconds, DisplayFields, SortRule, PermissionLevel)
VALUES
-- 1分钟 (60秒) 刷新一次
('能源总览', 60, '总能耗,总碳排放,今日水耗,今日气耗', '默认排序', '管理员'),

-- 5分钟 (300秒) 刷新一次 -> 光伏数据变化较慢，不需要太频繁
('光伏总览', 300, '光伏发电量,自用电量,并网电量,节能减排量', '按发电量降序', '能源管理员'),

-- 10秒 刷新一次 -> 运维监控需要高实时性
('配电网运行状态', 10, '变压器负载率,A/B/C三相电压,线圈温度', '按负载率降序', '运维人员'),

-- 30秒 刷新一次 -> 管理员看告警概览
('告警统计', 30, '高等级告警数,未处理告警占比,告警趋势图', '按严重程度降序', '管理员'),

-- 15秒 刷新一次 -> 运维看具体故障
('告警统计', 15, '实时告警列表,设备故障代码', '按时间降序', '运维人员');
GO

-- =============================================
-- 2) HistoryTrend 大量数据：两年日数据（5种能源）
--    时间范围：2024-01-01 ~ 2025-12-31
-- =============================================
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate   DATE = '2025-12-31';

;WITH N AS (
    SELECT 0 AS n
    UNION ALL SELECT n + 1 FROM N WHERE DATEADD(DAY, n + 1, @StartDate) <= @EndDate
),
D AS (
    SELECT DATEADD(DAY, n, @StartDate) AS d
    FROM N
),
E AS (
    SELECT v.EnergyType, v.BaseVal, v.IndustryAvg
    FROM (VALUES
        (N'电',     42000.0, 41000.0),
        (N'水',       800.0,   750.0),
        (N'蒸汽',     120.0,   110.0),
        (N'天然气',  2100.0,  2000.0),
        (N'光伏',    5000.0,  4600.0)
    ) v(EnergyType, BaseVal, IndustryAvg)
),
Daily AS (
    SELECT
        e.EnergyType,
        N'日' AS PeriodType,
        d.d AS StatTime,
        -- 造数逻辑：基线 + 季节性/周期性 + 随机扰动 + 周末下降（更贴近工厂场景）
        CONVERT(DECIMAL(18,3),
            CASE
                WHEN e.EnergyType = N'光伏' THEN
                    -- 光伏：冬季偏低、夏季偏高（用月份粗略模拟），再加扰动
                    (e.BaseVal
                     * CASE WHEN MONTH(d.d) IN (12,1,2) THEN 0.65
                            WHEN MONTH(d.d) IN (6,7,8)  THEN 1.15
                            ELSE 1.00 END
                     + (ABS(CHECKSUM(NEWID())) % 800) - 400
                    )
                ELSE
                    -- 非光伏：周末低、工作日高，再加扰动
                    (e.BaseVal
                     * CASE WHEN DATENAME(WEEKDAY, d.d) IN (N'星期六', N'星期日') THEN 0.65 ELSE 1.00 END
                     + (ABS(CHECKSUM(NEWID())) % 1200) - 600
                    )
            END
        ) AS Value,
        CONVERT(DECIMAL(18,3), e.IndustryAvg) AS IndustryAvgValue
    FROM D d
    CROSS JOIN E e
)
INSERT INTO dbo.HistoryTrend (EnergyType, PeriodType, StatTime, Value, IndustryAvgValue, YoYRate, MoMRate, TrendFlag)
SELECT EnergyType, PeriodType, StatTime,
       CASE WHEN Value < 0 THEN 0 ELSE Value END,  -- 防止极端扰动产生负数
       IndustryAvgValue,
       NULL, NULL, N'平稳'  -- 先占位，后面统一重算
FROM Daily
OPTION (MAXRECURSION 0);
GO

-- =============================================
-- 3) 由“日”自动聚合生成“周 / 月”
--    周：以 StatTime 所在周的周一作为周标识（简单一致）
--    月：每月1号作为月标识
-- =============================================
-- 周
INSERT INTO dbo.HistoryTrend (EnergyType, PeriodType, StatTime, Value, IndustryAvgValue, YoYRate, MoMRate, TrendFlag)
SELECT
    EnergyType,
    N'周' AS PeriodType,
    DATEADD(DAY, 1 - DATEPART(WEEKDAY, StatTime), StatTime) AS WeekStart,  -- 简易周起点（受 DATEFIRST 影响，但一致即可）
    CONVERT(DECIMAL(18,3), SUM(Value)) AS Value,
    CONVERT(DECIMAL(18,3), AVG(IndustryAvgValue)) AS IndustryAvgValue,
    NULL, NULL, N'平稳'
FROM dbo.HistoryTrend
WHERE PeriodType = N'日'
GROUP BY EnergyType, DATEADD(DAY, 1 - DATEPART(WEEKDAY, StatTime), StatTime);

-- 月
INSERT INTO dbo.HistoryTrend (EnergyType, PeriodType, StatTime, Value, IndustryAvgValue, YoYRate, MoMRate, TrendFlag)
SELECT
    EnergyType,
    N'月' AS PeriodType,
    DATEFROMPARTS(YEAR(StatTime), MONTH(StatTime), 1) AS MonthStart,
    CONVERT(DECIMAL(18,3), SUM(Value)) AS Value,
    CONVERT(DECIMAL(18,3), AVG(IndustryAvgValue)) AS IndustryAvgValue,
    NULL, NULL, N'平稳'
FROM dbo.HistoryTrend
WHERE PeriodType = N'日'
GROUP BY EnergyType, DATEFROMPARTS(YEAR(StatTime), MONTH(StatTime), 1);
GO

-- =============================================
-- 4) 批量重算 YoY/MoM/TrendFlag（日/周/月全部）
-- =============================================
EXEC dbo.usp_RecalcHistoryTrendRates '2024-01-01', '2025-12-31', NULL, N'日';
EXEC dbo.usp_RecalcHistoryTrendRates '2024-01-01', '2025-12-31', NULL, N'周';
EXEC dbo.usp_RecalcHistoryTrendRates '2024-01-01', '2025-12-31', NULL, N'月';
GO

-- =============================================
-- 5) RealtimeSummary 大量数据：30天分钟级（43200行）
--    时间范围：2025-12-01 00:00 ~ 2025-12-30 23:59
-- =============================================
DECLARE @RTStart DATETIME2(0) = '2025-12-01 00:00:00';
DECLARE @RTEnd   DATETIME2(0) = '2025-12-30 23:59:00';

;WITH N AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM N
    WHERE DATEADD(MINUTE, n + 1, @RTStart) <= @RTEnd
),
T AS (
    SELECT DATEADD(MINUTE, n, @RTStart) AS StatTime
    FROM N
),
R AS (
    SELECT
        StatTime,

        -- 造数：随时间递增 + 小幅波动
        CONVERT(DECIMAL(18,3), 20000 + DATEDIFF(MINUTE, @RTStart, StatTime) * 0.35 + (ABS(CHECKSUM(NEWID())) % 50) * 0.1) AS TotalElectricityKWh,
        CONVERT(DECIMAL(18,3),   600 + DATEDIFF(MINUTE, @RTStart, StatTime) * 0.01 + (ABS(CHECKSUM(NEWID())) % 10) * 0.1) AS TotalWaterM3,
        CONVERT(DECIMAL(18,3),   150 + DATEDIFF(MINUTE, @RTStart, StatTime) * 0.002 + (ABS(CHECKSUM(NEWID())) % 10) * 0.01) AS TotalSteamT,
        CONVERT(DECIMAL(18,3),  2600 + DATEDIFF(MINUTE, @RTStart, StatTime) * 0.04 + (ABS(CHECKSUM(NEWID())) % 20) * 0.1) AS TotalGasM3,

        -- 光伏：白天有、夜间低（简化：按小时段）
        CONVERT(DECIMAL(18,3),
            CASE WHEN DATEPART(HOUR, StatTime) BETWEEN 8 AND 16
                 THEN 1000 + (ABS(CHECKSUM(NEWID())) % 200) + DATEPART(HOUR, StatTime) * 30
                 ELSE 50 + (ABS(CHECKSUM(NEWID())) % 20)
            END
        ) AS TotalPvGenerationKWh,

        CONVERT(DECIMAL(18,3),
            CASE WHEN DATEPART(HOUR, StatTime) BETWEEN 8 AND 16
                 THEN 900 + (ABS(CHECKSUM(NEWID())) % 180) + DATEPART(HOUR, StatTime) * 25
                 ELSE 40 + (ABS(CHECKSUM(NEWID())) % 15)
            END
        ) AS PvSelfUseKWh,

        -- 告警：大多数时间 0~2，少量时间爆发
        CASE WHEN (ABS(CHECKSUM(NEWID())) % 1000) < 5 THEN 3 ELSE (ABS(CHECKSUM(NEWID())) % 2) END AS HighAlarmCount,
        CASE WHEN (ABS(CHECKSUM(NEWID())) % 1000) < 8 THEN 5 ELSE (ABS(CHECKSUM(NEWID())) % 3) END AS MediumAlarmCount,
        CASE WHEN (ABS(CHECKSUM(NEWID())) % 1000) < 10 THEN 8 ELSE (ABS(CHECKSUM(NEWID())) % 4) END AS LowAlarmCount
    FROM T
)
INSERT INTO dbo.RealtimeSummary
(
    StatTime,
    TotalElectricityKWh, TotalWaterM3, TotalSteamT, TotalGasM3,
    TotalPvGenerationKWh, PvSelfUseKWh,
    TotalAlarmCount, HighAlarmCount, MediumAlarmCount, LowAlarmCount
)
SELECT
    StatTime,
    TotalElectricityKWh, TotalWaterM3, TotalSteamT, TotalGasM3,
    TotalPvGenerationKWh, PvSelfUseKWh,
    (HighAlarmCount + MediumAlarmCount + LowAlarmCount) AS TotalAlarmCount,
    HighAlarmCount, MediumAlarmCount, LowAlarmCount
FROM R
OPTION (MAXRECURSION 0);
GO