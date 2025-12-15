CREATE VIEW V_Dashboard_Overview
AS
SELECT TOP 1 WITH TIES
    StatTime,
    TotalElectricityKWh,
    TotalWaterM3,
    TotalSteamT,
    TotalGasM3,
    TotalPvGenerationKWh,
    PvSelfUseKWh,
    TotalAlarmCount,
    HighAlarmCount,
    MediumAlarmCount,
    LowAlarmCount
FROM RealtimeSummary
ORDER BY ROW_NUMBER() OVER (ORDER BY StatTime DESC);