CREATE TABLE EquipmentAsset (
    AssetId INT IDENTITY(1,1) PRIMARY KEY,
    AssetName NVARCHAR(50) NOT NULL,
    EquipmentType NVARCHAR(20) NOT NULL, -- 变压器/水表/逆变器...
    ModelSpec NVARCHAR(50) NULL,
    InstallTime DATE NULL,
    WarrantyYears INT NULL,
    ScrapStatus NVARCHAR(10) NOT NULL DEFAULT N'正常使用', -- 正常使用/已报废
    RelatedDeviceType NVARCHAR(20) NULL, -- 变压器/光伏设备/能耗计量 等
    RelatedDeviceId INT NULL,
    CONSTRAINT CK_EquipmentAsset_Scrap
        CHECK (ScrapStatus IN (N'正常使用', N'已报废'))
);

CREATE TABLE Alarm (
    AlarmId BIGINT IDENTITY(1,1) PRIMARY KEY,
    AlarmType NVARCHAR(20) NOT NULL, -- 越限告警/通讯故障/设备故障
    RelatedDeviceType NVARCHAR(20) NULL,
    RelatedDeviceId INT NULL,
    OccurTime DATETIME2(0) NOT NULL,
    AlarmLevel NVARCHAR(10) NOT NULL, -- 高/中/低
    Content NVARCHAR(200) NOT NULL,
    ProcessStatus NVARCHAR(10) NOT NULL DEFAULT N'未处理', -- 未处理/处理中/已结案
    ThresholdDesc NVARCHAR(100) NULL,
    CONSTRAINT CK_Alarm_Level CHECK (AlarmLevel IN (N'高', N'中', N'低')),
    CONSTRAINT CK_Alarm_Status CHECK (ProcessStatus IN (N'未处理', N'处理中', N'已结案'))
);
CREATE INDEX IX_Alarm_OccurTime ON Alarm(OccurTime);

CREATE TABLE WorkOrder (
    WorkOrderId BIGINT IDENTITY(1,1) PRIMARY KEY,
    AlarmId BIGINT NOT NULL,
    MaintainerId INT NOT NULL,
    DispatchTime DATETIME2(0) NOT NULL,
    ResponseTime DATETIME2(0) NULL,
    CompleteTime DATETIME2(0) NULL,
    ResultDesc NVARCHAR(200) NULL,
    ReviewStatus NVARCHAR(10) NOT NULL DEFAULT N'未通过', -- 通过/未通过
    AttachmentPath NVARCHAR(200) NULL,
    CONSTRAINT FK_WorkOrder_Alarm FOREIGN KEY (AlarmId) REFERENCES Alarm(AlarmId),
    CONSTRAINT FK_WorkOrder_Maintainer FOREIGN KEY (MaintainerId) REFERENCES UserAccount(UserId),
    CONSTRAINT CK_WorkOrder_Review CHECK (ReviewStatus IN (N'通过', N'未通过'))
);
