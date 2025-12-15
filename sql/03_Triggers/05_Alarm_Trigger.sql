CREATE OR ALTER TRIGGER TR_Alarm_CreateWorkOrder
ON Alarm
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO WorkOrder(AlarmId, MaintainerId, DispatchTime)
    SELECT i.AlarmId, 4, SYSDATETIME()
    FROM inserted i
    WHERE i.AlarmLevel = N'高'
      AND NOT EXISTS (SELECT 1 FROM WorkOrder w WHERE w.AlarmId = i.AlarmId);

    UPDATE a
    SET ProcessStatus = N'处理中'
    FROM Alarm a
    INNER JOIN inserted i ON a.AlarmId = i.AlarmId
    WHERE i.AlarmLevel = N'高';
END;
GO

--工单复查通过后自动结案告警
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