CREATE TRIGGER TR_PvForecast_SetDeviation
ON PvForecast
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
    SET
        DeviationRate = CASE
                            WHEN i.ActualGenerationKWh IS NULL OR i.ForecastGenerationKWh = 0
                                 THEN NULL
                            ELSE (i.ActualGenerationKWh - i.ForecastGenerationKWh) * 100.0
                                 / i.ForecastGenerationKWh
                        END,
        NeedModelOptimize = CASE
                                WHEN i.ActualGenerationKWh IS NULL
                                     OR i.ForecastGenerationKWh = 0
                                     OR ABS(
                                         (i.ActualGenerationKWh - i.ForecastGenerationKWh) * 100.0
                                         / i.ForecastGenerationKWh
                                     ) <= 15
                                THEN 0
                                ELSE 1
                            END
    FROM PvForecast f
    JOIN inserted i ON f.ForecastId = i.ForecastId;
END;
GO