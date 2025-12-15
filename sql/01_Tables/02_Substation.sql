CREATE TABLE Substation (
    SubstationId INT IDENTITY(1,1) PRIMARY KEY,
    SubstationCode VARCHAR(20) NOT NULL UNIQUE,  -- 配电房编号
    FactoryId INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    LocationDesc NVARCHAR(100) NULL,
    VoltageLevel VARCHAR(10) NOT NULL,           -- 35KV/0.4KV
    TransformerCount INT NOT NULL CHECK (TransformerCount >= 0),
    CommissionDate DATE NULL,
    ResponsibleUserId INT NULL,
    ContactPhone VARCHAR(20) NULL,
    CONSTRAINT FK_Substation_Factory FOREIGN KEY (FactoryId)
        REFERENCES FactoryArea(FactoryId),
    CONSTRAINT FK_Substation_ResponsibleUser FOREIGN KEY (ResponsibleUserId)
        REFERENCES UserAccount(UserId),
    CONSTRAINT CK_Substation_Voltage CHECK (VoltageLevel IN ('35KV','0.4KV'))
);

CREATE TABLE Circuit (
    CircuitId INT IDENTITY(1,1) PRIMARY KEY,
    SubstationId INT NOT NULL,
    CircuitCode VARCHAR(20) NOT NULL,  -- 回路编号
    Name NVARCHAR(50) NULL,
    RatedVoltageKV DECIMAL(10,2) NULL,
    RatedCurrentA DECIMAL(10,2) NULL,
    CONSTRAINT UQ_Circuit UNIQUE(SubstationId, CircuitCode),
    CONSTRAINT FK_Circuit_Substation FOREIGN KEY (SubstationId)
        REFERENCES Substation(SubstationId)
);

CREATE TABLE Transformer (
    TransformerId INT IDENTITY(1,1) PRIMARY KEY,
    SubstationId INT NOT NULL,
    TransformerCode VARCHAR(20) NOT NULL,
    Name NVARCHAR(50) NULL,
    CapacityKVA DECIMAL(10,2) NULL,
    InstallDate DATE NULL,
    Status VARCHAR(10) NOT NULL DEFAULT N'正常', -- 正常/异常
    CONSTRAINT UQ_Transformer UNIQUE(SubstationId, TransformerCode),
    CONSTRAINT FK_Transformer_Substation FOREIGN KEY (SubstationId)
        REFERENCES Substation(SubstationId),
    CONSTRAINT CK_Transformer_Status CHECK (Status IN (N'正常', N'异常'))
);

CREATE TABLE CircuitMeasurement (
    DataId BIGINT IDENTITY(1,1) PRIMARY KEY,
    SubstationId INT NOT NULL,
    CircuitId INT NOT NULL,
    CollectTime DATETIME2(0) NOT NULL,
    VoltageKV DECIMAL(10,3) NULL,
    CurrentA DECIMAL(10,3) NULL,
    ActivePowerKW DECIMAL(10,3) NULL,
    ReactivePowerKVar DECIMAL(10,3) NULL,
    PowerFactor DECIMAL(5,3) NULL,
    ForwardActiveEnergyKWh DECIMAL(18,3) NULL,
    ReverseActiveEnergyKWh DECIMAL(18,3) NULL,
    SwitchStatus NVARCHAR(10) NOT NULL,    -- 分闸/合闸
    CableHeadTemp DECIMAL(5,2) NULL,
    CapacitorTemp DECIMAL(5,2) NULL,
    DataQualityStatus NVARCHAR(20) NOT NULL DEFAULT N'完整', -- 完整/数据不完整
    CONSTRAINT FK_CircuitMeasurement_Substation FOREIGN KEY (SubstationId)
        REFERENCES Substation(SubstationId),
    CONSTRAINT FK_CircuitMeasurement_Circuit FOREIGN KEY (CircuitId)
        REFERENCES Circuit(CircuitId),
    CONSTRAINT CK_CircuitMeasurement_SwitchStatus
        CHECK (SwitchStatus IN (N'分闸', N'合闸'))
);
CREATE INDEX IX_CircuitMeasurement_Time
    ON CircuitMeasurement(SubstationId, CircuitId, CollectTime);

CREATE TABLE TransformerMeasurement (
    DataId BIGINT IDENTITY(1,1) PRIMARY KEY,
    SubstationId INT NOT NULL,
    TransformerId INT NOT NULL,
    CollectTime DATETIME2(0) NOT NULL,
    LoadRate DECIMAL(5,2) NULL, -- 负载率 %
    WindingTemp DECIMAL(5,2) NULL,
    CoreTemp DECIMAL(5,2) NULL,
    EnvTemp DECIMAL(5,2) NULL,
    EnvHumidity DECIMAL(5,2) NULL,
    RunStatus NVARCHAR(10) NOT NULL DEFAULT N'正常',
    CONSTRAINT FK_TransformerMeasurement_Substation FOREIGN KEY (SubstationId)
        REFERENCES Substation(SubstationId),
    CONSTRAINT FK_TransformerMeasurement_Transformer FOREIGN KEY (TransformerId)
        REFERENCES Transformer(TransformerId),
    CONSTRAINT CK_TransformerMeasurement_Status
        CHECK (RunStatus IN (N'正常', N'异常'))
);
CREATE INDEX IX_TransformerMeasurement_Time
    ON TransformerMeasurement(SubstationId, TransformerId, CollectTime);

-- 插入的新表，为系统管理员服务
-- 1. 告警阈值配置表
CREATE TABLE AlarmThresholdConfig (
    RuleId INT IDENTITY(1,1) PRIMARY KEY,
    DeviceType NVARCHAR(20),   -- 例如 '变压器'
    MetricName NVARCHAR(50),   -- 例如 '绕组温度'
    ThresholdValue DECIMAL(18,2), -- 例如 120.00
    AlarmLevel NVARCHAR(10)    -- 例如 '高'
);