from fastapi import APIRouter
from backend.database import get_conn

router = APIRouter(prefix="/api/analyst", tags=["数据分析师"])

# 1. 光伏偏差分析（利用 PvForecast 表）
@router.get("/pv/analysis")
def get_pv_analysis(grid_point_id: int = 1): # 默认对齐到你的 1 号并网点
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 对齐日期排序：改为 ASC
        # 2. 对齐特定站点：加入 GridPointId 过滤
        sql = """
              SELECT
                  ForecastDate,
                  ForecastGenerationKWh,
                  ActualGenerationKWh,
                  DeviationRate
              FROM PvForecast
              WHERE GridPointId = %s
              ORDER BY ForecastDate ASC, TimeRange ASC \
              """
        cursor.execute(sql, (grid_point_id,))
        return cursor.fetchall()
    finally:
        conn.close()

# 2. 能效潜力识别：分析回路的基准负荷（利用 CircuitMeasurement 表）
@router.get("/energy/waste-identify")
def identify_waste():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 查询凌晨 2点 到 4点 的平均功率，识别那些关不掉的“幽灵负载”
        sql = """
              SELECT
                  c.Name as CircuitName,
                  AVG(m.ActivePowerKW) as MidnightAvgPower
              FROM CircuitMeasurement m
                       JOIN Circuit c ON m.CircuitId = c.CircuitId
              WHERE DATEPART(HOUR, m.CollectTime) BETWEEN 2 AND 4
              GROUP BY c.Name
              HAVING AVG(m.ActivePowerKW) > 5.0  -- 超过 5KW 的基准负载标记为关注点 \
              """
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()