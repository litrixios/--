CREATE TABLE DashboardConfig (
    ConfigId INT IDENTITY(1,1) PRIMARY KEY,
    ModuleCode VARCHAR(30) NOT NULL, -- 能源总览 / 光伏总览 / 配电网运行状态 / 告警统计
    RefreshIntervalSeconds INT NOT NULL, --秒 / 分钟
    DisplayFields NVARCHAR(200) NOT NULL, -- 总能耗 / 光伏发电量 / 高等级告警数
    SortRule NVARCHAR(50) NULL, -- 按时间降序 / 按能耗降序
    PermissionLevel NVARCHAR(20) NOT NULL -- 管理员/能源管理员/运维人员
);

-- 实时汇总数据（分钟级）
CREATE TABLE RealtimeSummary (
    SummaryId BIGINT IDENTITY(1,1) PRIMARY KEY,
    StatTime DATETIME2(0) NOT NULL,
    TotalElectricityKWh DECIMAL(18,3) NULL,
    TotalWaterM3 DECIMAL(18,3) NULL,
    TotalSteamT DECIMAL(18,3) NULL,
    TotalGasM3 DECIMAL(18,3) NULL,
    TotalPvGenerationKWh DECIMAL(18,3) NULL,
    PvSelfUseKWh DECIMAL(18,3) NULL,
    TotalAlarmCount INT NULL,
    HighAlarmCount INT NULL,
    MediumAlarmCount INT NULL,
    LowAlarmCount INT NULL
);

-- 历史趋势数据（日报/周报/月报）
CREATE TABLE HistoryTrend (
    TrendId BIGINT IDENTITY(1,1) PRIMARY KEY,
    EnergyType NVARCHAR(10) NOT NULL,  -- 电/水/蒸汽/天然气/光伏
    PeriodType NVARCHAR(10) NOT NULL,  -- 日/周/月
    StatTime DATE NOT NULL,
    Value DECIMAL(18,3) NOT NULL,
    YoYRate DECIMAL(5,2) NULL,         -- 同比 %
    MoMRate DECIMAL(5,2) NULL,         -- 环比 %
    IndustryAvgValue DECIMAL(18,3) NULL,
    TrendFlag NVARCHAR(10) NULL        -- 能耗上升/能耗下降
);
CREATE INDEX IX_HistoryTrend_TypeTime
    ON HistoryTrend(EnergyType, PeriodType, StatTime);