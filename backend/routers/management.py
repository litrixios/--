# backend/routers/management.py
from fastapi import APIRouter, Depends
from backend.database import get_conn
from typing import List

from backend.deps import require_role

router = APIRouter(
    prefix="/api/management",
    tags=["企业管理"],
    #dependencies=[Depends(require_role(["Manager", "manager", "Admin"]))]
)

# 映射字典：将前端的英文参数映射为数据库中的中文类型
ENERGY_TYPE_MAP = {
    'Power': '电',
    'Water': '水',
    'Gas': '天然气',
    'Steam': '蒸汽'
}

@router.get("/dashboard/overview")
def get_dashboard_overview():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 统计当月总能耗
        # 修正：改用 PeakValleyEnergy 表。
        # 原因：原 EnergyMeasurement 表中只有旧数据，而 PeakValleyEnergy 表包含根据当前时间(GETDATE)动态生成的日统计数据。
        sql_energy = """
            SELECT 
                SUM(CASE WHEN EnergyType = N'电' THEN TotalValue ELSE 0 END) as TotalPowerKWh,
                SUM(CASE WHEN EnergyType = N'水' THEN TotalValue ELSE 0 END) as TotalWaterM3,
                SUM(CASE WHEN EnergyType = N'天然气' THEN TotalValue ELSE 0 END) as TotalGasM3
            FROM PeakValleyEnergy
            WHERE MONTH(StatDate) = MONTH(GETDATE()) 
              AND YEAR(StatDate) = YEAR(GETDATE())
        """
        cursor.execute(sql_energy)
        energy_res = cursor.fetchone()

        # 2. 统计当月光伏发电
        # 修正：改用 PvForecast 表。
        # 原因：PvDailyStats 表不存在，且 PvGeneration 数据较旧。PvForecast 表包含动态生成的 ActualGenerationKWh（实际发电量）。
        sql_pv = """
            SELECT SUM(ActualGenerationKWh) as TotalPvGen
            FROM PvForecast
            WHERE MONTH(ForecastDate) = MONTH(GETDATE()) 
              AND YEAR(ForecastDate) = YEAR(GETDATE())
        """
        cursor.execute(sql_pv)
        pv_res = cursor.fetchone()

        # 处理空值情况
        energy_data = energy_res if energy_res else {}
        pv_data = pv_res if pv_res else {}

        return {
            "power_kwh": energy_data.get('TotalPowerKWh') or 0,
            "water_m3": energy_data.get('TotalWaterM3') or 0,
            "gas_m3": energy_data.get('TotalGasM3') or 0,
            "pv_gen_kwh": pv_data.get('TotalPvGen') or 0
        }
    finally:
        conn.close()


@router.get("/pv/revenue")
def get_pv_revenue_analysis():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 假设：平均工业电价 0.8 元/kWh
        # 修正：使用 PvForecast 表代替不存在的 PvDailyStats
        # 逻辑：查询近6个月的数据，使用 ActualGenerationKWh 近似作为自用电量计算收益
        sql = """
            SELECT 
                FORMAT(ForecastDate, 'yyyy-MM') as MonthStr,
                SUM(ActualGenerationKWh) as TotalSelfUse,
                CAST(SUM(ActualGenerationKWh) * 0.8 AS DECIMAL(18,2)) as SavedMoney
            FROM PvForecast
            WHERE ForecastDate >= DATEADD(MONTH, -6, GETDATE())
            GROUP BY FORMAT(ForecastDate, 'yyyy-MM')
            ORDER BY MonthStr ASC
        """
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()

# -----------------------------------------------------------------------------
# 3. 能耗溯源 (任务书 2.1.5 - “发现异常上升触发溯源”)
# 功能：按厂区/区域分组展示能耗占比，帮助管理层定位高耗能区域
# -----------------------------------------------------------------------------
@router.get("/energy/traceability")
def get_energy_traceability(energy_type: str = 'Power'):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 转换参数：将 'Power' 转为 '电'
        db_energy_type = ENERGY_TYPE_MAP.get(energy_type, '电')

        # 2. 修正 SQL 查询逻辑
        # 使用 PeakValleyEnergy (包含厂区 FactoryId) 关联 FactoryArea (包含厂区名称 Name)
        # 动态计算总数以求百分比
        sql = """
            SELECT 
                f.Name as AreaName,
                SUM(p.TotalValue) as TotalValue,
                CAST(
                    SUM(p.TotalValue) * 100.0 / 
                    NULLIF((SELECT SUM(TotalValue) FROM PeakValleyEnergy WHERE EnergyType=%s AND StatDate >= DATEADD(DAY, -30, GETDATE())), 0) 
                AS DECIMAL(10,2)) as Percentage
            FROM PeakValleyEnergy p
            JOIN FactoryArea f ON p.FactoryId = f.FactoryId
            WHERE p.EnergyType = %s
              AND p.StatDate >= DATEADD(DAY, -30, GETDATE()) -- 近30天
            GROUP BY f.Name
            ORDER BY TotalValue DESC
        """
        # 注意：参数 db_energy_type 需要传递两次，分别对应子查询和主查询中的占位符 %s
        cursor.execute(sql, (db_energy_type, db_energy_type))
        return cursor.fetchall()
    finally:
        conn.close()