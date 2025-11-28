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
    RoleCode VARCHAR(30) NOT NULL, -- EnergyAdmin / Maintainer / Analyst / Admin / Manager
    IsLocked BIT NOT NULL DEFAULT 0,
    FailedLoginCount INT NOT NULL DEFAULT 0,
    LastFailedTime DATETIME2(0) NULL
);