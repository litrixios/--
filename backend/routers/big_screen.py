# -*- coding: utf-8 -*-
from fastapi import APIRouter
from backend.database import get_conn
import logging
from datetime import datetime, date
import decimal

router = APIRouter(prefix="/api/big_screen", tags=["BigScreen"])

# 辅助函数：将 Decimal 转换为 float，处理 JSON 序列化问题
def decimal_to_float(value):
    if value is None:
        return 0.0
    if isinstance(value, decimal.Decimal):
        return float(value)
    return float(value)

# 核心逻辑：获取“演示日期”
# 如果今天是2026年，但数据库只有2024年的数据，这个函数会返回2024年最后一天
def get_simulation_date(cursor):
    try:
        # 查询 V_Energy_DailyByFactory 表中最近的一天
        cursor.execute("SELECT TOP 1 StatDate FROM V_Energy_DailyByFactory ORDER BY StatDate DESC")
        row = cursor.fetchone()
        if row and row.get('StatDate'):
            return row['StatDate']
    except Exception as e:
        logging.error(f"查找最近日期失败: {e}")
    # 如果查不到，默认返回系统当前时间
    return datetime.now().date()

@router.get("/data")
def get_big_screen_data():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)

    try:
        # 1. 确定统计日期 (关键！)
        target_date_obj = get_simulation_date(cursor)

        # 确保转为字符串 'YYYY-MM-DD'
        if isinstance(target_date_obj, (datetime, date)):
            target_date_str = target_date_obj.strftime("%Y-%m-%d")
        else:
            target_date_str = str(target_date_obj)

        logging.info(f"大屏数据展示日期: {target_date_str}")

        # 2. 初始化返回结构
        summary = {
            "daily_elec": 0.0,
            "daily_water": 0.0,
            "pv_gen": 0.0,
            "active_alarms": 0,
            "pv_self_use": 0.0,
            "high_alarms": 0,
            "month_alarms": 0,
            "pending_orders": 0
        }

        # 3. 获取核心指标 (根据 target_date_str)

        # 3.1 今日用电
        cursor.execute(f"SELECT SUM(TotalValue) as val FROM V_Energy_DailyByFactory WHERE EnergyType = N'电' AND StatDate = '{target_date_str}'")
        res = cursor.fetchone()
        if res: summary["daily_elec"] = decimal_to_float(res['val'])

        # 3.2 今日用水
        cursor.execute(f"SELECT SUM(TotalValue) as val FROM V_Energy_DailyByFactory WHERE EnergyType = N'水' AND StatDate = '{target_date_str}'")
        res = cursor.fetchone()
        if res: summary["daily_water"] = decimal_to_float(res['val'])

        # 3.3 光伏数据
        cursor.execute(f"SELECT SUM(TotalGenerationKWh) as gen, SUM(TotalSelfUseKWh) as self FROM V_Pv_DailyGeneration WHERE StatDate = '{target_date_str}'")
        res = cursor.fetchone()
        if res:
            summary["pv_gen"] = decimal_to_float(res['gen'])
            summary["pv_self_use"] = decimal_to_float(res['self'])

        # 3.4 实时告警 (查 Alarm 表，不限制日期，查状态为未处理的)
        cursor.execute("SELECT COUNT(*) as cnt FROM Alarm WHERE ProcessStatus IN (N'未处理', N'处理中')")
        res = cursor.fetchone()
        if res: summary["active_alarms"] = res['cnt']

        cursor.execute("SELECT COUNT(*) as cnt FROM Alarm WHERE AlarmLevel = N'高' AND ProcessStatus IN (N'未处理', N'处理中')")
        res = cursor.fetchone()
        if res: summary["high_alarms"] = res['cnt']

        # 3.5 待处理工单
        cursor.execute("SELECT COUNT(*) as cnt FROM WorkOrder WHERE ReviewStatus = N'未通过'")
        res = cursor.fetchone()
        if res: summary["pending_orders"] = res['cnt']

        # 4. 厂区能耗排行 (TOP 5)
        cursor.execute(f"""
            SELECT TOP 5 FactoryName as name, TotalValue as value
            FROM V_Energy_DailyByFactory
            WHERE EnergyType = N'电' AND StatDate = '{target_date_str}'
            ORDER BY TotalValue DESC
        """)
        rank_data_raw = cursor.fetchall()
        rank_data = [{"name": r['name'], "value": decimal_to_float(r['value'])} for r in rank_data_raw]

        # 5. 24小时用电趋势 (从 EnergyMeasurement 表查)
        # 注意：这里构造 0-23 小时的完整数据，数据库没数据的小时填 0
        cursor.execute(f"""
            SELECT DATEPART(HOUR, CollectTime) as h, SUM(Value) as val
            FROM EnergyMeasurement
            WHERE CAST(CollectTime AS DATE) = '{target_date_str}'
              AND MeterId IN (SELECT MeterId FROM EnergyMeter WHERE EnergyType = N'电')
            GROUP BY DATEPART(HOUR, CollectTime)
        """)
        trend_raw = cursor.fetchall()
        trend_dict = {row['h']: decimal_to_float(row['val']) for row in trend_raw}

        trend_data = []
        for h in range(24):
            trend_data.append({
                "hour": f"{h:02d}:00",
                "value": trend_dict.get(h, 0.0)
            })

        # 6. 实时高危告警列表 (Top 5)
        cursor.execute("""
            SELECT TOP 5
                a.Content, a.AlarmLevel, a.OccurTime, a.RelatedDeviceCode as DeviceName
            FROM Alarm a
            WHERE a.AlarmLevel = N'高'
            ORDER BY a.OccurTime DESC
        """)
        alarms_raw = cursor.fetchall()
        alarm_list = []
        for a in alarms_raw:
            alarm_list.append({
                "Content": a['Content'],
                "AlarmLevel": a['AlarmLevel'],
                "DeviceName": a['DeviceName'],
                "OccurTime": a['OccurTime'].strftime("%Y-%m-%d %H:%M:%S") if a['OccurTime'] else ""
            })

        # 7. 光伏最近7天趋势 (基于 target_date 往前推)
        cursor.execute(f"""
            SELECT TOP 7 StatDate, SUM(TotalGenerationKWh) as val
            FROM V_Pv_DailyGeneration
            WHERE StatDate <= '{target_date_str}'
            GROUP BY StatDate
            ORDER BY StatDate DESC
        """)
        pv_trend_raw = cursor.fetchall()
        # 翻转顺序，让日期从左到右递增
        pv_trend = []
        for item in reversed(pv_trend_raw):
            d_str = item['StatDate'].strftime("%m-%d") if item['StatDate'] else ""
            pv_trend.append({"date": d_str, "value": decimal_to_float(item['val'])})

        return {
            "display_date": target_date_str, # 告诉前端显示的哪天数据
            "summary": summary,
            "rank_data": rank_data,
            "trend_data": trend_data,
            "alarm_list": alarm_list,
            "trend_pv": pv_trend
        }

    except Exception as e:
        logging.error(f"大屏数据获取严重错误: {e}", exc_info=True)
        return {"error": str(e)}
    finally:
        conn.close()

@router.get("/alerts/high-level")
def get_high_level_alerts_api():
    # 简单实现，复用逻辑
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        cursor.execute("""
            SELECT AlarmType, COUNT(*) as count
            FROM Alarm WHERE AlarmLevel=N'高' GROUP BY AlarmType
        """)
        rows = cursor.fetchall()
        stats = [{"name": r['AlarmType'], "value": r['count']} for r in rows]
        return {"statistics": stats}
    except Exception:
        return {"statistics": []}
    finally:
        conn.close()