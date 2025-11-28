CREATE TRIGGER TR_TransformerMeasurement_Alarm
ON TransformerMeasurement
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Alarm(
        AlarmType, RelatedDeviceType, RelatedDeviceId, OccurTime,
        AlarmLevel, Content, ProcessStatus, ThresholdDesc
    )
    SELECT
        N'设备故障',
        N'变压器',
        i.TransformerId,
        i.CollectTime,
        CASE WHEN i.WindingTemp >= 120 THEN N'高' ELSE N'中' END,
        N'变压器ID=' + CAST(i.TransformerId AS NVARCHAR(20))
            + N' 绕组温度=' + CAST(i.WindingTemp AS NVARCHAR(20)) + N'℃',
        N'未处理',
        N'绕组温度阈值 120℃'
    FROM inserted i
    WHERE i.RunStatus = N'异常';
END;
GO