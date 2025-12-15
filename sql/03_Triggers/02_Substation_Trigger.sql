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

-- 变更逻辑，不再硬编码120，而是从AlarmThresholdConfig表里面查出来
ALTER TRIGGER TR_TransformerMeasurement_Alarm
ON TransformerMeasurement
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 定义变量来存阈值
    DECLARE @Threshold DECIMAL(18,2);

    -- 2. 动态从配置表读取阈值
    -- 逻辑：找“变压器”的“绕组温度”阈值，如果没有配置，默认给120
    SELECT @Threshold = ThresholdValue
    FROM AlarmThresholdConfig
    WHERE DeviceType = N'变压器' AND MetricName = N'绕组温度';

    -- 防止没配置导致空值
    IF @Threshold IS NULL SET @Threshold = 120;

    -- 3. 执行插入，使用变量 @Threshold
    INSERT INTO Alarm(
        AlarmType, RelatedDeviceType, RelatedDeviceId, OccurTime,
        AlarmLevel, Content, ProcessStatus, ThresholdDesc
    )
    SELECT
        N'设备故障',
        N'变压器',
        i.TransformerId,
        i.CollectTime,
        -- 动态判断：大于配置值就是 '高'
        CASE WHEN i.WindingTemp >= @Threshold THEN N'高' ELSE N'中' END,
        N'变压器ID=' + CAST(i.TransformerId AS NVARCHAR(20))
            + N' 绕组温度=' + CAST(i.WindingTemp AS NVARCHAR(20)) + N'℃',
        N'未处理',
        -- 记录当前触发时的阈值
        N'绕组温度阈值 ' + CAST(@Threshold AS NVARCHAR(20)) + N'℃'
    FROM inserted i
    WHERE i.RunStatus = N'异常';
END;
GO
