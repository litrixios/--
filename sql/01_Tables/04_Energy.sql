CREATE TABLE EnergyMeter (
    MeterId INT IDENTITY(1,1) PRIMARY KEY,
    MeterCode VARCHAR(30) NOT NULL UNIQUE,
    EnergyType NVARCHAR(10) NOT NULL, -- 水/蒸汽/天然气/电
    InstallLocation NVARCHAR(100) NULL,
    PipeSpec NVARCHAR(20) NULL, -- DN25 等
    CommProtocol VARCHAR(20) NULL,
    RunStatus NVARCHAR(10) NOT NULL DEFAULT N'正常', -- 正常/故障
    CalibrationCycleMonths INT NULL,
    Manufacturer NVARCHAR(50) NULL,
    FactoryId INT NOT NULL,
    CONSTRAINT FK_EnergyMeter_Factory FOREIGN KEY (FactoryId)
        REFERENCES FactoryArea(FactoryId),
    CONSTRAINT CK_EnergyMeter_Type CHECK (EnergyType IN (N'水', N'蒸汽', N'天然气', N'电')),
    CONSTRAINT CK_EnergyMeter_Status CHECK (RunStatus IN (N'正常', N'故障'))
);

CREATE TABLE EnergyMeasurement (
    DataId BIGINT IDENTITY(1,1) PRIMARY KEY,
    MeterId INT NOT NULL,
    CollectTime DATETIME2(0) NOT NULL,
    Value DECIMAL(18,3) NOT NULL,
    Unit NVARCHAR(10) NOT NULL, -- m?/t/kWh
    DataQuality NVARCHAR(10) NOT NULL DEFAULT N'优', -- 优/良/中/差
    FactoryId INT NOT NULL,
    NeedVerify BIT NOT NULL DEFAULT 0, -- 数据质量中/差 -> 待核实
    CONSTRAINT FK_EnergyMeasurement_Meter FOREIGN KEY (MeterId)
        REFERENCES EnergyMeter(MeterId),
    CONSTRAINT FK_EnergyMeasurement_Factory FOREIGN KEY (FactoryId)
        REFERENCES FactoryArea(FactoryId)
);
CREATE INDEX IX_EnergyMeasurement_Time
    ON EnergyMeasurement(FactoryId, CollectTime);

CREATE TABLE PeakValleyEnergy (
    RecordId INT IDENTITY(1,1) PRIMARY KEY,
    EnergyType NVARCHAR(10) NOT NULL, -- 电/水/蒸汽/天然气
    FactoryId INT NOT NULL,
    StatDate DATE NOT NULL,
    SharpPeriodValue DECIMAL(18,3) NULL, -- 尖峰
    PeakPeriodValue DECIMAL(18,3) NULL,  -- 高峰
    FlatPeriodValue DECIMAL(18,3) NULL,  -- 平段
    ValleyPeriodValue DECIMAL(18,3) NULL,-- 低谷
    TotalValue DECIMAL(18,3) NULL,
    PeakValleyPrice DECIMAL(10,4) NULL,  -- 峰谷电价
    EnergyCost DECIMAL(18,2) NULL,       -- 能耗成本
    CONSTRAINT FK_PeakValleyEnergy_Factory FOREIGN KEY (FactoryId)
        REFERENCES FactoryArea(FactoryId),
    CONSTRAINT CK_PeakValleyEnergy_Type CHECK (EnergyType IN (N'电', N'水', N'蒸汽', N'天然气')),
    CONSTRAINT UQ_PeakValley UNIQUE(EnergyType, FactoryId, StatDate)
);
