from fastapi import APIRouter, HTTPException
from backend.database import get_conn

from backend.models import WorkOrderCreateRequest, WorkOrderFinishRequest
from datetime import datetime

router = APIRouter(prefix="/api/operator", tags=["运维人员"])


# ==========================================
# 1. 告警管理：查看待处理的高危告警
# ==========================================
@router.get("/alarm/pending-high")
def get_high_priority_alarms():
    """
    功能：对应截图里的“接收通知，及时响应高等级告警”。
    逻辑：只查 AlarmLevel='高' 且 Status='未处理' 的记录。
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = """
            SELECT * FROM Alarm 
            WHERE AlarmLevel = N'高' AND ProcessStatus = N'未处理'
            ORDER BY OccurTime DESC
        """
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()


# ==========================================
# 2. 工单流程：接单 (响应告警)
# ==========================================
@router.post("/workorder/dispatch")
def create_work_order(request: WorkOrderCreateRequest):
    """
    功能：运维人员看到告警后，点击“立即处理”，系统生成一张工单。
    测试举例：
    {
      "alarm_id": 1,
      "maintainer_id": 1
    }
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 1. 插入工单表 (WorkOrder)
        # DispatchTime 设为当前时间
        insert_sql = """
            INSERT INTO WorkOrder (AlarmId, MaintainerId, DispatchTime, ReviewStatus)
            VALUES (%d, %d, GETDATE(), N'未通过')
        """
        cursor.execute(insert_sql, (request.alarm_id, request.maintainer_id))

        # 2. 修改告警表状态 (Alarm) -> 变为 '处理中'
        update_sql = "UPDATE Alarm SET ProcessStatus = N'处理中' WHERE AlarmId = %d"
        cursor.execute(update_sql, (request.alarm_id,))

        conn.commit()
        return {"msg": "接单成功，工单已生成", "alarm_id": request.alarm_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 3. 工单流程：完工 (填写结果)
# ==========================================
@router.post("/workorder/complete")
def complete_work_order(request: WorkOrderFinishRequest):
    """
    功能：对应截图里的“填写处理结果并上传附件”。
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 1. 更新工单：填入完成时间、结果、附件路径
        # 注意：ResultDesc 是 Nvarchar，虽然 pymssql 现在大部分能处理，但加 N 前缀更保险
        sql_wo = """
            UPDATE WorkOrder 
            SET CompleteTime = GETDATE(),
                ResultDesc = %s,
                AttachmentPath = %s
            WHERE WorkOrderId = %d
        """
        cursor.execute(sql_wo, (request.result_desc, request.attachment_path, request.work_order_id))

        # 2. 级联更新：把关联的告警状态改为 '已结案'
        # 这里用了一个子查询技巧：通过 WorkOrderId 找到对应的 AlarmId
        sql_alarm = """
            UPDATE Alarm 
            SET ProcessStatus = N'已结案' 
            WHERE AlarmId = (SELECT AlarmId FROM WorkOrder WHERE WorkOrderId = %d)
        """
        cursor.execute(sql_alarm, (request.work_order_id,))

        conn.commit()
        return {"msg": "维修已完成，告警已关闭"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 4. 设备台账：查看负责区域设备及维保建议
# ==========================================
@router.get("/assets/maintenance-plan")
def get_maintenance_plan():
    """
    功能：对应截图“查看设备台账，制定维护计划”。
    亮点：后端自动计算设备是否快过保了。
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 查出设备信息
        cursor.execute("SELECT * FROM EquipmentAsset")
        assets = cursor.fetchall()

        # Python 处理逻辑：增加一个 'MaintenanceTips' 字段
        current_year = datetime.now().year

        for asset in assets:
            install_date = asset.get('InstallTime')  # 可能是字符串或datetime对象
            warranty_years = asset.get('WarrantyYears', 0)

            # 简单的逻辑：如果 (安装年份 + 质保年限) <= 今年，提示要维保
            # 注意：这里需要处理 install_date 可能是 None 的情况
            if install_date:
                # 假设 install_date 是字符串 '2020-01-01'，截取前4位转int
                # 这里的处理取决于 pymssql 返回的是 datetime 对象还是字符串
                # 为了保险，我们用 try-except 处理
                try:
                    install_year = int(str(install_date)[:4])
                    expire_year = install_year + warranty_years

                    if expire_year <= current_year:
                        asset['MaintenanceTips'] = "⚠️ 质保已到期，建议立即巡检"
                    elif expire_year == current_year + 1:
                        asset['MaintenanceTips'] = "ℹ️ 明年到期，列入计划"
                    else:
                        asset['MaintenanceTips'] = "状态良好"
                except:
                    asset['MaintenanceTips'] = "日期格式错误"
            else:
                asset['MaintenanceTips'] = "无安装日期"

        return assets
    finally:
        conn.close()