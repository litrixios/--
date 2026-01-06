# backend/routers/manager.py
from fastapi import APIRouter, HTTPException, Depends
from backend.database import get_conn
from backend.deps import require_role
from backend.models import AuditRequest
from datetime import datetime, timedelta  # 新增导入
import decimal

router = APIRouter(
    prefix="/api/energy_manager",
    tags=["能源管理"],
    #dependencies=[Depends(require_role(["EnergyManager", "Admin"]))]
)

@router.get("/report")
def get_energy_report(area_name: str = None,energy_type: str = None):
    # 功能：查询视图
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = "SELECT * FROM V_Energy_Report WHERE 1=1"
        if area_name:
            sql += f" AND AreaName = N'{area_name}'"
        if energy_type:
            sql += f" AND EnergyType = N'{energy_type}'"
        sql += " ORDER BY CollectTime DESC"
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()

@router.get("/audit/pending")
def get_pending_audit_list():
    # 功能：看管理员有哪些“红色异常数据”需要处理
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        cursor.execute("SELECT * FROM V_Energy_Report WHERE NeedVerify = 1")
        return cursor.fetchall()
    finally:
        conn.close()

@router.post("/audit/verify")
def verify_energy_data(request: AuditRequest):
    # 功能：管理员点击“通过”或“驳回”后，更新数据库状态
    conn = get_conn()
    cursor = conn.cursor()
    try:

        if request.is_valid:
            new_quality = '已核实'
        else:
            new_quality = '确认故障'

        sql = """
            UPDATE EnergyMeasurement
            SET NeedVerify = 0,       -- 英文列名，正确
                DataQuality = %s      -- 英文列名，正确
            WHERE DataId = %d         -- 英文列名，正确
        """
        cursor.execute(sql, (new_quality, request.data_id))
        conn.commit()
        return {"msg": "Success"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
# --- 新增接口：历史趋势分析报告 ---
@router.get("/analysis")
def get_energy_analysis(month: str = "2025-11", area_name: str = None, energy_type: str = u"电"):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 确定对比时间点
        d = datetime.strptime(month + "-01", "%Y-%m-%d")
        last_month = (d - timedelta(days=1)).strftime("%Y-%m") # 环比月份
        last_year = f"{d.year - 1}-{d.month:02d}"             # 同比月份

        def get_monthly_sum(target_month):
            sql = """
                SELECT SUM(TotalValue) as total FROM V_Energy_DailyByFactory
                WHERE StatDate LIKE %s AND EnergyType = %s
            """
            params = [target_month + "%", energy_type]
            if area_name:
                sql += " AND FactoryName = %s"
                params.append(area_name)
            cursor.execute(sql, params)
            res = cursor.fetchone()
            return float(res['total']) if res and res['total'] else 0.0

        curr_val = get_monthly_sum(month)
        prev_val = get_monthly_sum(last_month)
        year_val = get_monthly_sum(last_year)

        # 2. 计算对比率
        mom = ((curr_val - prev_val) / prev_val * 100) if prev_val > 0 else 0
        yoy = ((curr_val - year_val) / year_val * 100) if year_val > 0 else 0

        # 3. 获取每日明细趋势
        cursor.execute("""
            SELECT StatDate as date, SUM(TotalValue) as value FROM V_Energy_DailyByFactory
            WHERE StatDate LIKE %s AND EnergyType = %s GROUP BY StatDate ORDER BY StatDate
        """, [month + "%", energy_type])
        trend = [{"date": str(r['date']), "value": float(r['value'])} for r in cursor.fetchall()]

        return {
            "current_total": round(curr_val, 2),
            "mom": round(mom, 2),
            "yoy": round(yoy, 2),
            "trend": trend,
            "period": month
        }
    finally:
        conn.close()
# --- 新增接口：获取所有厂区列表 ---
@router.get("/area/list")
def get_area_list():
    """获取所有厂区名称（去重）"""
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 从视图中获取去重的厂区列表
        sql = "SELECT DISTINCT AreaName FROM V_Energy_Report ORDER BY AreaName"
        cursor.execute(sql)
        areas = cursor.fetchall()

        # 如果没有数据，返回示例数据
        if not areas:
            return [
                {"AreaName": "城南工业园主厂区"},
                {"AreaName": "城北新能源分厂"},
                {"AreaName": "东郊光伏产业园"}
            ]

        return areas
    except Exception as e:
        # 如果视图不存在或出错，返回示例数据
        print(f"获取厂区列表失败: {str(e)}")
        return [
            {"AreaName": "城南工业园主厂区"},
            {"AreaName": "城北新能源分厂"},
            {"AreaName": "东郊光伏产业园"},
            {"AreaName": "西郊综合能源基地"},
            {"AreaName": "滨海化工园区"}
        ]
    finally:
        conn.close()
