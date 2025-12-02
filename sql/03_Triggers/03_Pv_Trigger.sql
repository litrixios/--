-- 创建触发器：当光伏预测表有插入或更新操作时，自动计算偏差率和优化标记
CREATE TRIGGER TR_PvForecast_SetDeviation
ON PvForecast  -- 作用于光伏预测表
AFTER INSERT, UPDATE  -- 在插入或更新操作之后触发
AS
BEGIN
    -- 禁止显示受影响的行数消息（提高性能）
    SET NOCOUNT ON;

    -- 更新光伏预测表中的数据
    UPDATE f  -- f 代表 PvForecast 表（原始数据表）
    SET
        -- 计算偏差率（实现图片中"偏差率超15%时触发"的要求）
        DeviationRate = CASE
                            -- 检查数据完整性：实际值或预测值为空/零时不计算
                            WHEN i.ActualGenerationKWh IS NULL OR i.ForecastGenerationKWh = 0
                                 THEN NULL  -- 数据不完整，设为NULL
                            -- 计算偏差率公式：(实际-预测)/预测 × 100%
                            ELSE ABS((i.ActualGenerationKWh - i.ForecastGenerationKWh) * 100.0
                                 / i.ForecastGenerationKWh)
                        END,

        -- 设置模型优化标记（实现图片中"预测模型优化提醒"功能）
        NeedModelOptimize = CASE
                                -- 数据不完整时不需要优化
                                WHEN i.ActualGenerationKWh IS NULL
                                     OR i.ForecastGenerationKWh = 0
                                     -- 偏差率绝对值小于等于15%时不需要优化
                                     OR ABS(
                                         (i.ActualGenerationKWh - i.ForecastGenerationKWh) * 100.0
                                         / i.ForecastGenerationKWh
                                     ) <= 15  -- 图片要求的15%阈值
                                THEN 0  -- 标记为不需要优化
                                ELSE 1  -- 偏差率>15%，标记为需要优化模型
                            END

    -- 从光伏预测表（别名f）中更新数据
    FROM PvForecast f
    -- 关联插入的数据（别名i） - i代表新插入或更新的数据
    JOIN inserted i ON f.ForecastId = i.ForecastId  -- 通过ForecastId关联对应记录
END;
GO