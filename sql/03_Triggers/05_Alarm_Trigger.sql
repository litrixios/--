CREATE TRIGGER TR_Alarm_CreateWorkOrder
ON Alarm
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO WorkOrder(
        AlarmId, MaintainerId, DispatchTime
    )
    SELECT
        i.AlarmId,
        1,                 -- 先写死一个运维人员ID，项目里可以通过算法选择最近的人
        SYSDATETIME()
    FROM inserted i
    WHERE i.AlarmLevel = N'高';
END;
GO