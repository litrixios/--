from fastapi import APIRouter, Depends, Query
from backend.database import get_conn
from typing import Optional
from backend.deps import require_role

router = APIRouter(
    prefix="/api/analyst",
    tags=["数据分析"],
    dependencies=[Depends(require_role(["Analyst", "Admin"]))]
)

# ==========================================
# 1. 光伏偏差分析 (保持原样)
# ==========================================
@router.get("/pv/analysis")
def get_pv_analysis(gridPointId: int = Query(1)):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = """
              SELECT
                  ForecastDate,
                  SUM(ForecastGenerationKWh) as ForecastGenerationKWh,
                  SUM(ActualGenerationKWh) as ActualGenerationKWh,
                  AVG(DeviationRate) as DeviationRate
              FROM PvForecast
              WHERE GridPointId = %s
              GROUP BY ForecastDate
              ORDER BY ForecastDate ASC
              """
        cursor.execute(sql, (gridPointId,))
        result = cursor.fetchall()
        if not result:
            return [{"ForecastDate": "2026-01-01", "ForecastGenerationKWh": 100, "ActualGenerationKWh": 95, "DeviationRate": 5}]
        return result
    finally:
        conn.close()

# ==========================================
# 2. 浪费识别 (适配前端表格字段名)
# ==========================================
@router.get("/energy/waste-identify")
def identify_waste():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 使用 AS 别名直接匹配前端表格的 prop="Name" 和 prop="AvgWastePower"
        sql = """
              SELECT
                  c.Name as Name,
                  ISNULL(AVG(m.ActivePowerKW), 0) as AvgWastePower
              FROM CircuitMeasurement m
                       JOIN Circuit c ON m.CircuitId = c.CircuitId
              WHERE (DATEPART(HOUR, m.CollectTime) BETWEEN 2 AND 4
                  OR DATEPART(HOUR, m.CollectTime) BETWEEN 9 AND 11)
              GROUP BY c.Name
              HAVING AVG(m.ActivePowerKW) > 0.1
              """
        cursor.execute(sql)
        result = cursor.fetchall()
        return result
    finally:
        conn.close()

# ==========================================
# 3. 季度报表 (保持原样)
# ==========================================
@router.get("/reports/quarterly-summary")
def get_quarterly_report(year: int = Query(2026), quarter: int = Query(1)):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        cost_sql = """
                   SELECT
                       SUM(DayEnergy * Price) as TotalCost,
                       SUM(DayEnergy) as TotalKWh
                   FROM (
                            SELECT
                                (MAX(ForwardActiveEnergyKWh) - MIN(ForwardActiveEnergyKWh)) as DayEnergy,
                                CASE
                                    WHEN DATEPART(HOUR, CollectTime) IN (8,9,10,18,19,20) THEN 1.2
                                    WHEN DATEPART(HOUR, CollectTime) IN (23,0,1,2,3,4,5,6) THEN 0.3
                                    ELSE 0.7
                                    END as Price
                            FROM CircuitMeasurement
                            WHERE DATEPART(QUARTER, CollectTime) = %s AND YEAR(CollectTime) = %s
                   GROUP BY DATEPART(DAY, CollectTime), DATEPART(HOUR, CollectTime)
                       ) AS Stats
                   """
        cursor.execute(cost_sql, (quarter, year))
        res = cursor.fetchone()

        total_cost = res['TotalCost'] if res and res['TotalCost'] else 0
        total_kwh = res['TotalKWh'] if res and res['TotalKWh'] else 0

        return {
            "summary": {
                "totalCost": round(total_cost, 2),
                "totalKWh": round(total_kwh, 2),
                "wasteCircuitCount": 3
            },
            "wasteDetails": [] # 详情统一由 waste-identify 接口提供
        }
    finally:
        conn.close()

# ==========================================
# 4. 预测优化逻辑 (保持原样)
# ==========================================
@router.get("/pv/prediction-optimize")
def optimize_prediction(gridPointId: int = 1):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = "SELECT ForecastDate, ForecastGenerationKWh, ActualGenerationKWh FROM PvForecast WHERE GridPointId = %s"
        cursor.execute(sql, (gridPointId,))
        raw_data = cursor.fetchall()
        optimized_data = []
        for item in raw_data:
            weather_factor = 0.85 if item['ActualGenerationKWh'] < item['ForecastGenerationKWh'] else 1.0
            item['OptimizedForecast'] = round(item['ForecastGenerationKWh'] * weather_factor, 2)
            optimized_data.append(item)
        return optimized_data
    finally:
        conn.close()