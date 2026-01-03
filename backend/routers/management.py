# backend/routers/management.py
from fastapi import APIRouter
from backend.database import get_conn
from typing import List

router = APIRouter(prefix="/api/management", tags=["企业管理层"])

@router.get("/dashboard/overview")
def get_dashboard_overview():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 统计当月总能耗与光伏发电
        # 注意：这里使用简单的聚合查询，实际项目中可能需要关联具体的设备类型ID
        sql_energy = """
            SELECT 
                SUM(CASE WHEN EnergyType = 'Power' THEN Value ELSE 0 END) as TotalPowerKWh,
                SUM(CASE WHEN EnergyType = 'Water' THEN Value ELSE 0 END) as TotalWaterM3,
                SUM(CASE WHEN EnergyType = 'Gas'   THEN Value ELSE 0 END) as TotalGasM3
            FROM EnergyMeasurement
            WHERE MONTH(CollectTime) = MONTH(GETDATE()) 
              AND YEAR(CollectTime) = YEAR(GETDATE())
        """
        cursor.execute(sql_energy)
        energy_res = cursor.fetchone()

        sql_pv = """
            SELECT SUM(DailyGenerationKWh) as TotalPvGen
            FROM PvDailyStats
            WHERE MONTH(StatDate) = MONTH(GETDATE()) 
              AND YEAR(StatDate) = YEAR(GETDATE())
        """
        cursor.execute(sql_pv)
        pv_res = cursor.fetchone()

        return {
            "power_kwh": energy_res['TotalPowerKWh'] or 0,
            "water_m3": energy_res['TotalWaterM3'] or 0,
            "gas_m3": energy_res['TotalGasM3'] or 0,
            "pv_gen_kwh": pv_res['TotalPvGen'] or 0
        }
    finally:
        conn.close()


@router.get("/pv/revenue")
def get_pv_revenue_analysis():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 假设：平均工业电价 0.8 元/kWh
        # 逻辑：查询近6个月的光伏自用电量，并乘以电价
        sql = """
            SELECT 
                FORMAT(StatDate, 'yyyy-MM') as MonthStr,
                SUM(SelfUseKWh) as TotalSelfUse,
                SUM(SelfUseKWh) * 0.8 as SavedMoney
            FROM PvDailyStats
            WHERE StatDate >= DATEADD(MONTH, -6, GETDATE())
            GROUP BY FORMAT(StatDate, 'yyyy-MM')
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
        # 关联 EnergyMeasurement -> Device -> Area
        # 假设有一个 Area 表或 Device 表中有 AreaId
        sql = """
            SELECT 
                a.AreaName,
                SUM(m.Value) as TotalValue,
                CAST(SUM(m.Value) * 100.0 / (SELECT SUM(Value) FROM EnergyMeasurement WHERE EnergyType=%s) AS DECIMAL(10,2)) as Percentage
            FROM EnergyMeasurement m
            JOIN Device d ON m.DeviceId = d.DeviceId
            JOIN Area a ON d.AreaId = a.AreaId
            WHERE m.EnergyType = %s
              AND m.CollectTime >= DATEADD(DAY, -30, GETDATE()) -- 近30天
            GROUP BY a.AreaName
            ORDER BY TotalValue DESC
        """
        cursor.execute(sql, (energy_type, energy_type))
        return cursor.fetchall()
    finally:
        conn.close()