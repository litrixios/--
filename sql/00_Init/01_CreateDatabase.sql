-- 文件路径：sql/00_Init/01_CreateDatabase.sql
USE master;
GO

-- 1. 检查数据库是否存在，如果存在，为了保证环境干净，先删除它
-- (注意：这会删除旧数据！仅限开发阶段使用)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'SmartEnergyDB')
BEGIN
    -- 强制断开其他连接，防止删除失败
    ALTER DATABASE [SmartEnergyDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [SmartEnergyDB];
END
GO

-- 2. 新建数据库
CREATE DATABASE [SmartEnergyDB];
GO

-- 3. 切换到该数据库
USE [SmartEnergyDB];
GO

PRINT '数据库 SmartEnergyDB 创建成功！';