--历史趋势：存储过程（自动算同比/环比 + 自动 TrendFlag）
CREATE OR ALTER PROCEDURE dbo.usp_InsertHistoryTrend
    @EnergyType       NVARCHAR(10),   -- 电/水/蒸汽/天然气/光伏
    @PeriodType       NVARCHAR(10),   -- 日/周/月
    @StatTime         DATE,
    @Value            DECIMAL(18,3),
    @IndustryAvgValue DECIMAL(18,3) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Value IS NULL OR @Value < 0
        THROW 50001, N'Value 不能为空且不能为负数。', 1;

    IF @PeriodType NOT IN (N'日', N'周', N'月')
        THROW 50002, N'PeriodType 仅支持：日/周/月。', 1;

    IF @EnergyType NOT IN (N'电', N'水', N'蒸汽', N'天然气', N'光伏')
        THROW 50003, N'EnergyType 不在允许范围：电/水/蒸汽/天然气/光伏。', 1;

    DECLARE @PrevPeriodDate DATE =
        CASE @PeriodType
            WHEN N'日' THEN DATEADD(DAY,  -1, @StatTime)
            WHEN N'周' THEN DATEADD(WEEK, -1, @StatTime)
            WHEN N'月' THEN DATEADD(MONTH,-1, @StatTime)
        END;

    DECLARE @PrevYearDate DATE = DATEADD(YEAR, -1, @StatTime);

    DECLARE @PrevValue DECIMAL(18,3) =
    (
        SELECT TOP (1) ht.Value
        FROM HistoryTrend ht WITH (READCOMMITTEDLOCK)
        WHERE ht.EnergyType = @EnergyType
          AND ht.PeriodType = @PeriodType
          AND ht.StatTime   = @PrevPeriodDate
        ORDER BY ht.StatTime DESC
    );

    DECLARE @PrevYearValue DECIMAL(18,3) =
    (
        SELECT TOP (1) ht.Value
        FROM HistoryTrend ht WITH (READCOMMITTEDLOCK)
        WHERE ht.EnergyType = @EnergyType
          AND ht.PeriodType = @PeriodType
          AND ht.StatTime   = @PrevYearDate
        ORDER BY ht.StatTime DESC
    );

    DECLARE @MoMRate DECIMAL(5,2) = NULL;
    DECLARE @YoYRate DECIMAL(5,2) = NULL;

    IF @PrevValue IS NOT NULL AND @PrevValue <> 0
        SET @MoMRate = ROUND(((@Value - @PrevValue) / NULLIF(@PrevValue, 0)) * 100.0, 2);

    IF @PrevYearValue IS NOT NULL AND @PrevYearValue <> 0
        SET @YoYRate = ROUND(((@Value - @PrevYearValue) / NULLIF(@PrevYearValue, 0)) * 100.0, 2);

    DECLARE @BasisRate DECIMAL(5,2) = COALESCE(@MoMRate, @YoYRate);

    -- ? 规则：缺对照期（@BasisRate IS NULL）也归为“平稳”
    DECLARE @TrendFlag NVARCHAR(10) =
        CASE
            WHEN @BasisRate IS NULL THEN N'平稳'
            WHEN @BasisRate > 0     THEN N'能耗上升'
            WHEN @BasisRate < 0     THEN N'能耗下降'
            ELSE N'平稳'
        END;

    INSERT INTO HistoryTrend (EnergyType, PeriodType, StatTime, Value, YoYRate, MoMRate, IndustryAvgValue, TrendFlag)
    VALUES (@EnergyType, @PeriodType, @StatTime, @Value, @YoYRate, @MoMRate, @IndustryAvgValue, @TrendFlag);
END;
GO

--历史趋势：触发器兜底（如果有人绕过存储过程手工 insert）
CREATE OR ALTER TRIGGER dbo.tr_HistoryTrend_SetTrendFlag
ON dbo.HistoryTrend
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ht
    SET TrendFlag =
        CASE
            WHEN COALESCE(i.MoMRate, i.YoYRate) IS NULL THEN N'平稳'
            WHEN COALESCE(i.MoMRate, i.YoYRate) > 0     THEN N'能耗上升'
            WHEN COALESCE(i.MoMRate, i.YoYRate) < 0     THEN N'能耗下降'
            ELSE N'平稳'
        END
    FROM dbo.HistoryTrend ht
    INNER JOIN inserted i ON i.TrendId = ht.TrendId;
END;
GO


CREATE OR ALTER PROCEDURE dbo.usp_RecalcHistoryTrendRates
    @FromDate DATE,
    @ToDate   DATE,
    @EnergyType NVARCHAR(10) = NULL,
    @PeriodType NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Base AS (
        SELECT
            ht.TrendId,
            ht.EnergyType,
            ht.PeriodType,
            ht.StatTime,
            ht.Value,
            LAG(ht.Value) OVER (PARTITION BY ht.EnergyType, ht.PeriodType ORDER BY ht.StatTime) AS PrevValue
        FROM dbo.HistoryTrend ht
        WHERE ht.StatTime BETWEEN @FromDate AND @ToDate
          AND (@EnergyType IS NULL OR ht.EnergyType = @EnergyType)
          AND (@PeriodType IS NULL OR ht.PeriodType = @PeriodType)
    ),
    Calc AS (
        SELECT
            b.TrendId,
            -- 环比：先计算原始值，再限制范围，最后转换为 DECIMAL(5,2)
            CASE WHEN b.PrevValue IS NULL OR b.PrevValue = 0
                 THEN NULL
                 ELSE
                    -- 步骤1：计算原始增长率（高精度避免计算溢出）
                    CONVERT(DECIMAL(18,6), ROUND(((b.Value - b.PrevValue) / CAST(b.PrevValue AS DECIMAL(18,6))) * 100.0, 2))
            END AS RawMoMRate,
            -- 同比：同上
            CASE WHEN y.Value IS NULL OR y.Value = 0
                 THEN NULL
                 ELSE
                    CONVERT(DECIMAL(18,6), ROUND(((b.Value - y.Value) / CAST(y.Value AS DECIMAL(18,6))) * 100.0, 2))
            END AS RawYoYRate
        FROM Base b
        LEFT JOIN dbo.HistoryTrend y
               ON y.EnergyType = b.EnergyType
              AND y.PeriodType = b.PeriodType
              AND y.StatTime   = DATEADD(YEAR, -1, b.StatTime)
    ),
    LimitRange AS (
        SELECT
            TrendId,
            -- 步骤2：限制环比范围在 -999.99 ~ 999.99 之间
            CASE
                WHEN RawMoMRate IS NULL THEN NULL
                WHEN RawMoMRate > 999.99 THEN 999.99
                WHEN RawMoMRate < -999.99 THEN -999.99
                ELSE RawMoMRate
            END AS NewMoMRate,
            -- 步骤3：限制同比范围在 -999.99 ~ 999.99 之间
            CASE
                WHEN RawYoYRate IS NULL THEN NULL
                WHEN RawYoYRate > 999.99 THEN 999.99
                WHEN RawYoYRate < -999.99 THEN -999.99
                ELSE RawYoYRate
            END AS NewYoYRate
        FROM Calc
    )
    UPDATE ht
    SET
        -- 步骤4：最终转换为 DECIMAL(5,2)，确保匹配字段类型
        ht.MoMRate = CONVERT(DECIMAL(5,2), c.NewMoMRate),
        ht.YoYRate = CONVERT(DECIMAL(5,2), c.NewYoYRate),
        ht.TrendFlag =
            CASE
                WHEN COALESCE(c.NewMoMRate, c.NewYoYRate) IS NULL THEN N'平稳'
                WHEN COALESCE(c.NewMoMRate, c.NewYoYRate) > 0     THEN N'能耗上升'
                WHEN COALESCE(c.NewMoMRate, c.NewYoYRate) < 0     THEN N'能耗下降'
                ELSE N'平稳'
            END
    FROM dbo.HistoryTrend ht
    INNER JOIN LimitRange c ON c.TrendId = ht.TrendId;
END;
GO