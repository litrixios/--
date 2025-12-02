CREATE TABLE FactoryArea (
    FactoryId INT IDENTITY(1,1) PRIMARY KEY,
    FactoryCode VARCHAR(20) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100) NULL
);

CREATE TABLE UserAccount (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(50) NOT NULL UNIQUE,
    RealName NVARCHAR(50) NOT NULL,
    PasswordHash VARBINARY(64) NOT NULL,
    Phone VARCHAR(20) NULL,
    RoleCode VARCHAR(30) NOT NULL, -- 能源管理员 / 运维人员 / 数据分析师 / 系统管理员 / 企业管理层 / 运维工单管理员
    IsLocked BIT NOT NULL DEFAULT 0,
    FailedLoginCount INT NOT NULL DEFAULT 0,
    LastFailedTime DATETIME2(0) NULL
);