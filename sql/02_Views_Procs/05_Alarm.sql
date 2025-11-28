CREATE VIEW V_Alarm_HandlingEfficiency
AS
SELECT
    s.SubstationId,
    s.SubstationCode,
    s.Name AS SubstationName,
    COUNT(DISTINCT a.AlarmId) AS HighAlarmCount,
    AVG(DATEDIFF(MINUTE, w.DispatchTime, w.CompleteTime) * 1.0) AS AvgHandleMinutes
FROM Alarm a
JOIN WorkOrder w ON a.AlarmId = w.AlarmId
LEFT JOIN Substation s
    ON a.RelatedDeviceType = N'≈‰µÁ∑ø' AND a.RelatedDeviceId = s.SubstationId
WHERE a.AlarmLevel = N'∏ﬂ'
GROUP BY s.SubstationId, s.SubstationCode, s.Name;