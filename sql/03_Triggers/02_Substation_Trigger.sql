CREATE OR ALTER TRIGGER TR_TransformerMeasurement_Alarm
ON TransformerMeasurement
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) 定义变量存阈值
    DECLARE @Threshold DECIMAL(18,2);

    -- 2) 动态从配置表读取阈值：变压器-绕组温度；无配置则默认 120
    SELECT @Threshold = ThresholdValue
    FROM AlarmThresholdConfig
    WHERE DeviceType = N'变压器' AND MetricName = N'绕组温度';

    IF @Threshold IS NULL SET @Threshold = 120;

    -- 3) 插入告警：写入 RelatedDeviceCode（TransformerCode）
    INSERT INTO Alarm(
        AlarmType, RelatedDeviceCode, OccurTime,
        AlarmLevel, Content, ProcessStatus, ThresholdDesc
    )
    SELECT
        N'设备故障',
        t.TransformerCode,
        i.CollectTime,
        CASE WHEN i.WindingTemp >= @Threshold THEN N'高' ELSE N'中' END,
        N'变压器编码=' + CAST(t.TransformerCode AS NVARCHAR(30))
            + N' 绕组温度=' + CAST(i.WindingTemp AS NVARCHAR(20)) + N'℃',
        N'未处理',
        N'绕组温度阈值 ' + CAST(@Threshold AS NVARCHAR(20)) + N'℃'
    FROM inserted i
    INNER JOIN Transformer t
        ON t.TransformerId = i.TransformerId
    WHERE i.RunStatus = N'异常'
      -- 重要：避免 Alarm 外键失败（要求设备先在 EquipmentAsset 建档）
      AND EXISTS (
          SELECT 1
          FROM EquipmentAsset ea
          WHERE ea.RelatedDeviceCode = t.TransformerCode
      );
END;
GO
