# -*- coding: utf-8 -*-
from fastapi import APIRouter
from backend.database import get_conn
import logging
from datetime import datetime, timedelta
from typing import Optional
import decimal

router = APIRouter(prefix="/api/big_screen", tags=["BigScreen"])

def decimal_to_float(value):
    """安全转换 decimal.Decimal 为 float"""
    if value is None:
        return 0.0
    if isinstance(value, decimal.Decimal):
        return float(value)
    return float(value)

@router.get("/data")
def get_big_screen_data():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)

    try:
        # 1. 获取核心概览指标
        summary = {
            "daily_elec": 0.0,
            "daily_water": 0.0,
            "pv_gen": 0.0,
            "active_alarms": 0.0,
            "pv_self_use": 0.0,
            "high_alarms": 0.0,
            "month_alarms": 0.0,
            "pending_orders": 0.0
        }

        # 1.1 获取今日用电量
        try:
            cursor.execute("""
                SELECT SUM(TotalValue) as daily_elec
                FROM V_Energy_DailyByFactory
                WHERE EnergyType = N'电' AND StatDate = CAST(GETDATE() AS DATE)
            """)
            elec_result = cursor.fetchone()
            if elec_result and elec_result.get("daily_elec") is not None:
                summary["daily_elec"] = decimal_to_float(elec_result["daily_elec"])
        except Exception as e:
            logging.warning(f"获取今日用电量失败: {e}")

        # 1.2 获取今日用水量
        try:
            cursor.execute("""
                SELECT SUM(TotalValue) as daily_water
                FROM V_Energy_DailyByFactory
                WHERE EnergyType = N'水' AND StatDate = CAST(GETDATE() AS DATE)
            """)
            water_result = cursor.fetchone()
            if water_result and water_result.get("daily_water") is not None:
                summary["daily_water"] = decimal_to_float(water_result["daily_water"])
        except Exception as e:
            logging.warning(f"获取今日用水量失败: {e}")

        # 1.3 获取今日光伏发电量
        try:
            cursor.execute("""
                SELECT
                    SUM(TotalGenerationKWh) as pv_gen,
                    SUM(TotalSelfUseKWh) as pv_self_use
                FROM V_Pv_DailyGeneration
                WHERE StatDate = CAST(GETDATE() AS DATE)
            """)
            pv_result = cursor.fetchone()
            if pv_result:
                summary["pv_gen"] = decimal_to_float(pv_result.get("pv_gen", 0))
                summary["pv_self_use"] = decimal_to_float(pv_result.get("pv_self_use", 0))
        except Exception as e:
            logging.warning(f"获取光伏发电量失败: {e}")

        # 1.4 获取活跃告警数
        try:
            cursor.execute("""
                SELECT
                    COUNT(*) as active_alarms,
                    SUM(CASE WHEN AlarmLevel = N'高' THEN 1 ELSE 0 END) as high_alarms
                FROM Alarm
                WHERE ProcessStatus IN (N'未处理', N'处理中')
            """)
            alarm_result = cursor.fetchone()
            if alarm_result:
                summary["active_alarms"] = decimal_to_float(alarm_result.get("active_alarms", 0))
                summary["high_alarms"] = decimal_to_float(alarm_result.get("high_alarms", 0))
        except Exception as e:
            logging.warning(f"获取活跃告警数失败: {e}")

        # 1.5 获取本月告警总数
        try:
            cursor.execute("""
                SELECT COUNT(*) as month_alarms
                FROM Alarm
                WHERE MONTH(OccurTime) = MONTH(GETDATE())
                  AND YEAR(OccurTime) = YEAR(GETDATE())
            """)
            month_alarm_result = cursor.fetchone()
            if month_alarm_result:
                summary["month_alarms"] = decimal_to_float(month_alarm_result.get("month_alarms", 0))
        except Exception as e:
            logging.warning(f"获取本月告警总数失败: {e}")

        # 1.6 获取待处理工单数
        try:
            cursor.execute("SELECT COUNT(*) as count FROM WorkOrder WHERE ReviewStatus = N'未通过'")
            pending_result = cursor.fetchone()
            if pending_result:
                summary["pending_orders"] = decimal_to_float(pending_result.get("count", 0))
        except Exception as e:
            logging.warning(f"获取待处理工单数失败: {e}")

        # 2. 厂区能耗排行
        cursor.execute("""
            SELECT TOP 5 FactoryName as name, TotalValue as value
            FROM V_Energy_DailyByFactory
            WHERE EnergyType = N'电'
              AND StatDate = CAST(GETDATE() AS DATE)
            ORDER BY TotalValue DESC
        """)
        rank_data = cursor.fetchall()

        for item in rank_data:
            item["value"] = decimal_to_float(item.get("value", 0))
            item["name"] = item.get("name", "未知厂区")

        # 3. 24小时能耗趋势
        cursor.execute("""
            SELECT
                DATEPART(HOUR, CollectTime) as hour,
                SUM(Value) as value
            FROM EnergyMeasurement em
            WHERE CAST(CollectTime AS DATE) = CAST(GETDATE() AS DATE)
              AND MeterId IN (SELECT MeterId FROM EnergyMeter WHERE EnergyType = N'电')
            GROUP BY DATEPART(HOUR, CollectTime)
            ORDER BY hour
        """)
        trend_data = cursor.fetchall()

        for item in trend_data:
            item["value"] = decimal_to_float(item.get("value", 0))
            item["hour"] = int(item.get("hour", 0))

        # 4. 实时报警列表
        cursor.execute("""
            SELECT TOP 5
                Content,
                AlarmLevel,
                OccurTime,
                AlarmType,
                RelatedDeviceCode as DeviceName
            FROM Alarm
            WHERE AlarmLevel = N'高'
            ORDER BY OccurTime DESC
        """)
        alarm_list = cursor.fetchall()

        for alert in alarm_list:
            if alert.get("OccurTime"):
                if isinstance(alert["OccurTime"], datetime):
                    alert["OccurTime"] = alert["OccurTime"].strftime("%Y-%m-%d %H:%M:%S")

        # 5. 光伏发电趋势
        cursor.execute("""
            SELECT TOP 7
                StatDate as date,
                SUM(TotalGenerationKWh) as value
            FROM V_Pv_DailyGeneration
            WHERE StatDate >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
            GROUP BY StatDate
            ORDER BY StatDate
        """)
        trend_pv = cursor.fetchall()

        for item in trend_pv:
            item["value"] = decimal_to_float(item.get("value", 0))
            if isinstance(item.get("date"), datetime):
                item["date"] = item["date"].strftime("%Y-%m-%d")

        return {
            "summary": summary,
            "rank_data": rank_data,
            "trend_data": trend_data,
            "alarm_list": alarm_list,
            "trend_pv": trend_pv
        }

    except Exception as e:
        logging.error(f"大屏数据读取失败: {str(e)}")
        return {
            "summary": {
                "daily_elec": 0.0,
                "daily_water": 0.0,
                "pv_gen": 0.0,
                "active_alarms": 0.0,
                "pv_self_use": 0.0,
                "high_alarms": 0.0,
                "month_alarms": 0.0,
                "pending_orders": 0.0
            },
            "rank_data": [],
            "trend_data": [],
            "alarm_list": [],
            "trend_pv": []
        }
    finally:
        conn.close()


# 新增接口：光伏收益计算
@router.get("/pv/revenue")
def get_pv_revenue(month: Optional[str] = None):
    """
    计算光伏收益
    month: 月份格式 '2024-01'，不传则计算当前月
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)

    try:
        if month:
            year, month_num = map(int, month.split('-'))
            start_date = datetime(year, month_num, 1)
            if month_num == 12:
                end_date = datetime(year + 1, 1, 1)
            else:
                end_date = datetime(year, month_num + 1, 1)
        else:
            # 默认当前月
            now = datetime.now()
            start_date = datetime(now.year, now.month, 1)
            if now.month == 12:
                end_date = datetime(now.year + 1, 1, 1)
            else:
                end_date = datetime(now.year, now.month + 1, 1)

        # 计算自用电量节省的电费（假设电价0.6元/kWh）
        cursor.execute("""
            SELECT
                SUM(TotalSelfUseKWh) as total_self_use,
                SUM(TotalFeedInKWh) as total_feed_in
            FROM V_Pv_DailyGeneration
            WHERE StatDate >= %s AND StatDate < %s
        """, (start_date, end_date))

        result = cursor.fetchone()

        total_self_use = decimal_to_float(result["total_self_use"]) if result and result["total_self_use"] else 0.0
        total_feed_in = decimal_to_float(result["total_feed_in"]) if result and result["total_feed_in"] else 0.0

        # 计算收益
        # 自用电节省：0.6元/kWh
        # 上网电收益：0.4元/kWh（假设上网电价）
        self_use_saving = total_self_use * 0.6
        feed_in_revenue = total_feed_in * 0.4
        total_revenue = self_use_saving + feed_in_revenue

        return {
            "month": month or f"{now.year}-{now.month:02d}",
            "total_generation": (total_self_use + total_feed_in),
            "self_use_kwh": total_self_use,
            "feed_in_kwh": total_feed_in,
            "self_use_saving": round(self_use_saving, 2),
            "feed_in_revenue": round(feed_in_revenue, 2),
            "total_revenue": round(total_revenue, 2),
            "saving_unit": "元"
        }

    except Exception as e:
        logging.error(f"光伏收益计算失败: {str(e)}")
        return {"error": str(e)}
    finally:
        conn.close()


# 新增接口：能耗总结报告
@router.get("/energy/report")
def get_energy_report(period: str = "month", year_month: Optional[str] = None):
    """
    获取能耗总结报告
    period: month-月度, quarter-季度, year-年度
    year_month: 格式 '2024-01'，不传则当前月/季度/年
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)

    try:
        # 确定时间范围
        now = datetime.now()
        if year_month:
            year, month = map(int, year_month.split('-'))
        else:
            year, month = now.year, now.month

        if period == "month":
            start_date = datetime(year, month, 1)
            if month == 12:
                end_date = datetime(year + 1, 1, 1)
            else:
                end_date = datetime(year, month + 1, 1)
            period_desc = f"{year}年{month}月"

        elif period == "quarter":
            quarter = (month - 1) // 3 + 1
            start_month = (quarter - 1) * 3 + 1
            start_date = datetime(year, start_month, 1)
            end_month = start_month + 3
            if end_month > 12:
                end_date = datetime(year + 1, end_month - 12, 1)
            else:
                end_date = datetime(year, end_month, 1)
            period_desc = f"{year}年第{quarter}季度"

        else:  # year
            start_date = datetime(year, 1, 1)
            end_date = datetime(year + 1, 1, 1)
            period_desc = f"{year}年"

        # 查询本期能耗
        cursor.execute("""
            SELECT
                EnergyType,
                SUM(TotalValue) as total_value
            FROM V_Energy_DailyByFactory
            WHERE StatDate >= %s AND StatDate < %s
            GROUP BY EnergyType
        """, (start_date, end_date))

        current_data = {}
        for row in cursor.fetchall():
            current_data[row["EnergyType"]] = decimal_to_float(row["total_value"])

        # 查询同期对比（去年同期/上季度）
        if period == "month":
            compare_start = start_date - timedelta(days=365)
            compare_end = end_date - timedelta(days=365)
        elif period == "quarter":
            compare_start = start_date - timedelta(days=365)
            compare_end = end_date - timedelta(days=365)
        else:  # year
            compare_start = datetime(year - 1, 1, 1)
            compare_end = datetime(year, 1, 1)

        cursor.execute("""
            SELECT
                EnergyType,
                SUM(TotalValue) as total_value
            FROM V_Energy_DailyByFactory
            WHERE StatDate >= %s AND StatDate < %s
            GROUP BY EnergyType
        """, (compare_start, compare_end))

        compare_data = {}
        for row in cursor.fetchall():
            compare_data[row["EnergyType"]] = decimal_to_float(row["total_value"])

        # 计算节能降耗指标
        report = {
            "period": period_desc,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": (end_date - timedelta(days=1)).strftime("%Y-%m-%d"),
            "current_consumption": {},
            "compare_consumption": {},
            "saving_analysis": {},
            "target_completion": {}
        }

        # 填充数据并计算同比
        energy_types = ['电', '水', '蒸汽', '气']
        for energy in energy_types:
            current = current_data.get(energy, 0.0)
            compare = compare_data.get(energy, 0.0)

            report["current_consumption"][energy] = current
            report["compare_consumption"][energy] = compare

            if compare > 0:
                change_percent = ((current - compare) / compare) * 100
                report["saving_analysis"][energy] = {
                    "change": round(change_percent, 1),
                    "trend": "下降" if change_percent < 0 else "上升",
                    "absolute_change": round(current - compare, 2)
                }
            else:
                report["saving_analysis"][energy] = {
                    "change": 0.0,
                    "trend": "无对比数据",
                    "absolute_change": 0.0
                }

            # 假设目标：比去年同期降低5%
            target_rate = -5.0
            if compare > 0:
                actual_rate = ((current - compare) / compare) * 100
                completed = actual_rate <= target_rate
                report["target_completion"][energy] = {
                    "target": target_rate,
                    "actual": round(actual_rate, 1),
                    "completed": completed,
                    "gap": round(actual_rate - target_rate, 1) if not completed else 0
                }
            else:
                report["target_completion"][energy] = {
                    "target": target_rate,
                    "actual": 0.0,
                    "completed": False,
                    "gap": abs(target_rate)
                }

        return report

    except Exception as e:
        logging.error(f"能耗报告生成失败: {str(e)}")
        return {"error": str(e)}
    finally:
        conn.close()


# 新增接口：高等级告警推送
@router.get("/alerts/high-level")
def get_high_level_alerts(limit: int = 10):
    """
    获取高等级告警推送
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)

    try:
        cursor.execute(f"""
            SELECT TOP {limit}
                AlarmId,
                Content,
                AlarmType,
                AlarmLevel,
                OccurTime,
                RelatedDeviceCode as DeviceName,
                EquipmentType,
                DATEDIFF(MINUTE, OccurTime, GETDATE()) as UnhandledMinutes
            FROM Alarm
            WHERE AlarmLevel = N'高' AND ProcessStatus IN (N'未处理', N'处理中')
            ORDER BY OccurTime DESC
        """)

        alerts = cursor.fetchall()

        # 计算紧急程度
        for alert in alerts:
            unhandled_minutes = alert.get("UnhandledMinutes", 0)
            if unhandled_minutes > 60:
                alert["UrgencyLevel"] = "紧急"
            elif unhandled_minutes > 30:
                alert["UrgencyLevel"] = "重要"
            else:
                alert["UrgencyLevel"] = "一般"

            if isinstance(alert.get("OccurTime"), datetime):
                alert["OccurTime"] = alert["OccurTime"].strftime("%Y-%m-%d %H:%M:%S")

        # 统计各类高等级告警
        cursor.execute("""
            SELECT
                AlarmType,
                COUNT(*) as count,
                AVG(DATEDIFF(MINUTE, OccurTime, GETDATE())) as avg_response_time
            FROM Alarm
            WHERE AlarmLevel = N'高' AND ProcessStatus IN (N'未处理', N'处理中')
            GROUP BY AlarmType
        """)

        stats = cursor.fetchall()

        for stat in stats:
            stat["count"] = int(decimal_to_float(stat["count"]))
            stat["avg_response_time"] = decimal_to_float(stat["avg_response_time"])

        return {
            "alerts": alerts,
            "statistics": stats,
            "total_high_alerts": len(alerts),
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

    except Exception as e:
        logging.error(f"获取高等级告警失败: {str(e)}")
        return {"error": str(e)}
    finally:
        conn.close()
