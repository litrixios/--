# backend/routers/manager.py
from fastapi import APIRouter, HTTPException, Depends
from backend.database import get_conn
from backend.deps import require_role
from backend.models import AuditRequest

router = APIRouter(
    prefix="/api/energy",
    tags=["能源管理"],
    dependencies=[Depends(require_role(["EnergyManager", "Admin"]))]
)

@router.get("/report")
def get_energy_report(area_name: str = None):
    # 功能：查询视图
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = "SELECT * FROM V_Energy_Report"
        if area_name:
            sql += f" WHERE AreaName = N'{area_name}'"
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