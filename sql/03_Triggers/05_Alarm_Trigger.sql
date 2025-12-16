--默认运维id为6，高等级告警（如 “变压器绕组温度超 120℃”）在 15 分钟内自动触发派单
-- CREATE OR ALTER TRIGGER TR_Alarm_CreateWorkOrder
-- ON Alarm
-- AFTER INSERT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--
--     INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime)
--     SELECT i.AlarmId, 6, SYSDATETIME()
--     FROM inserted i
--     WHERE i.AlarmLevel = N'高'
--       AND NOT EXISTS (SELECT 1 FROM WorkOrder w WHERE w.AlarmId = i.AlarmId);
--
--     UPDATE a
--     SET ProcessStatus = N'处理中'
--     FROM Alarm a
--     INNER JOIN inserted i ON a.AlarmId = i.AlarmId
--     WHERE i.AlarmLevel = N'高';
-- END;
-- GO

--工单复查，将ReviewStatus修改为通过后，自动结案告警
CREATE TRIGGER TR_WorkOrder_ReviewPass_CloseAlarm
ON WorkOrder
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(ReviewStatus)
    BEGIN
        UPDATE a SET ProcessStatus = N'已结案'
        FROM Alarm a
        INNER JOIN inserted i ON a.AlarmId = i.AlarmId
        WHERE i.ReviewStatus = N'通过';
    END
END
GO