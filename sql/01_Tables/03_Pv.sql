CREATE TABLE PvGridPoint (
    GridPointId INT IDENTITY(1,1) PRIMARY KEY,
    GridPointCode VARCHAR(20) NOT NULL UNIQUE,
    Name NVARCHAR(50) NULL,
    Location NVARCHAR(100) NULL
);

CREATE TABLE PvDevice (
    DeviceId INT IDENTITY(1,1) PRIMARY KEY,
    DeviceCode VARCHAR(30) NOT NULL UNIQUE,
    DeviceType NVARCHAR(20) NOT NULL, -- 逆变器/汇流箱
    GridPointId INT NOT NULL,
    InstallLocation NVARCHAR(100) NULL,
    CapacityKWP DECIMAL(10,2) NULL,
    CommissionDate DATE NULL,
    CalibrationCycleMonths INT NULL,
    RunStatus NVARCHAR(10) NOT NULL DEFAULT N'正常', -- 正常/故障/离线
    CommProtocol VARCHAR(20) NULL, -- RS485/Lora
    CONSTRAINT FK_PvDevice_GridPoint FOREIGN KEY (GridPointId)
        REFERENCES PvGridPoint(GridPointId),
    CONSTRAINT CK_PvDevice_Type CHECK (DeviceType IN (N'逆变器', N'汇流箱')),
    CONSTRAINT CK_PvDevice_Status CHECK (RunStatus IN (N'正常', N'故障', N'离线'))
);

CREATE TABLE PvGeneration (
    DataId BIGINT IDENTITY(1,1) PRIMARY KEY,
    DeviceId INT NOT NULL,
    GridPointId INT NOT NULL,
    CollectTime DATETIME2(0) NOT NULL,
    GenerationKWh DECIMAL(18,3) NULL,
    FeedInKWh DECIMAL(18,3) NULL,
    SelfUseKWh DECIMAL(18,3) NULL,
    InverterEfficiency DECIMAL(5,2) NULL, -- %
    StringVoltageV DECIMAL(10,2) NULL,
    StringCurrentA DECIMAL(10,2) NULL,
    CONSTRAINT FK_PvGeneration_Device FOREIGN KEY (DeviceId)
        REFERENCES PvDevice(DeviceId),
    CONSTRAINT FK_PvGeneration_GridPoint FOREIGN KEY (GridPointId)
        REFERENCES PvGridPoint(GridPointId)
);
CREATE INDEX IX_PvGeneration_Time
    ON PvGeneration(GridPointId, CollectTime);

CREATE TABLE PvForecast (
    ForecastId BIGINT IDENTITY(1,1) PRIMARY KEY,
    GridPointId INT NOT NULL,
    ForecastDate DATE NOT NULL,
    TimeRange NVARCHAR(20) NOT NULL, -- 08:00-09:00
    ForecastGenerationKWh DECIMAL(18,3) NOT NULL,
    ActualGenerationKWh DECIMAL(18,3) NULL,
    DeviationRate DECIMAL(5,2) NULL, -- 偏差率 %
    ModelVersion NVARCHAR(20) NULL,
    NeedModelOptimize BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_PvForecast_GridPoint FOREIGN KEY (GridPointId)
        REFERENCES PvGridPoint(GridPointId)
);
CREATE UNIQUE INDEX UQ_PvForecast
    ON PvForecast(GridPointId, ForecastDate, TimeRange);
