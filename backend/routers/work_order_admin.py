from fastapi import APIRouter, HTTPException, Query, Depends
from backend.database import get_conn
from backend.models import WorkOrderCreateRequest, AlarmDismissRequest, WorkOrderReviewRequest, RemindRequest
from backend.deps import require_role

router = APIRouter(
    prefix="/api/wo-admin",
    tags=["工单管理"],
    dependencies=[Depends(require_role(["WorkOrderAdmin", "Admin"]))]
)


# ==========================================
# 职责一：审核告警信息真实性，排除数据误报
# ==========================================

@router.get("/alarms/pending")
def get_pending_alarms():
    """获取所有待审核的告警（状态为'未处理'）"""
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = """
            SELECT A.*, D.AssetName 
            FROM Alarm A
            LEFT JOIN EquipmentAsset D ON A.RelatedDeviceCode = D.RelatedDeviceCode
            WHERE A.ProcessStatus = N'未处理'
            ORDER BY A.OccurTime DESC
        """
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()


@router.post("/alarm/dismiss")
def dismiss_false_alarm(req: AlarmDismissRequest):
    """
    功能：判定为误报（如通讯波动导致的离线），直接关闭告警。
    操作：将告警状态设为'已结案'，并在内容中备注误报原因。
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 在原有告警内容后追加误报备注
        sql = """
            UPDATE Alarm 
            SET ProcessStatus = N'已结案', 
                Content = Content + N' [管理员已忽略: ' + %s + N']'
            WHERE AlarmId = %d
        """
        cursor.execute(sql, (req.reason, req.alarm_id))
        conn.commit()
        return {"msg": f"告警 {req.alarm_id} 已确认为误报并关闭"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 职责二：生成并分配工单，跟踪进度
# ==========================================

@router.get("/maintainers")
def get_available_maintainers():
    """获取所有运维人员列表，用于派单选择"""
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = "SELECT UserId, RealName, Phone FROM UserAccount WHERE RoleCode = 'Maintainer'"
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()


@router.post("/dispatch")
def assign_work_order(req: WorkOrderCreateRequest):
    """
    功能：生成工单并分配给指定运维人员。
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 1. 插入工单表
        insert_sql = """
            INSERT INTO WorkOrder (AlarmId, MaintainerId, DispatchTime, ReviewStatus)
            VALUES (%d, %d, GETDATE(), N'未通过')
        """
        cursor.execute(insert_sql, (req.alarm_id, req.maintainer_id))

        # 2. 修改告警状态为 '处理中'
        update_sql = "UPDATE Alarm SET ProcessStatus = N'处理中' WHERE AlarmId = %d"
        cursor.execute(update_sql, (req.alarm_id,))

        conn.commit()
        return {"msg": "派单成功"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


@router.get("/monitor")
def monitor_work_orders(overdue_hours: int = 24):
    """
    功能：跟踪工单进度（如超时未响应提醒）。
    逻辑：查找派单时间超过 X 小时且尚未完工（CompleteTime IS NULL）的工单。
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # SQL Server 使用 DATEDIFF 计算时间差
        sql = f"""
            SELECT W.*, U.RealName as MaintainerName, A.Content as AlarmContent
            FROM WorkOrder W
            JOIN UserAccount U ON W.MaintainerId = U.UserId
            JOIN Alarm A ON W.AlarmId = A.AlarmId
            WHERE W.CompleteTime IS NULL 
            AND DATEDIFF(hour, W.DispatchTime, GETDATE()) >= %d
        """
        cursor.execute(sql, (overdue_hours,))
        return cursor.fetchall()
    finally:
        conn.close()


@router.post("/remind")
def remind_maintainer(req: RemindRequest):
    """
    功能：发送提醒（此处模拟发送消息）
    目前暂未实现
    """
    # 在实际系统中，这里会调用短信API或WebSocket推送
    return {"msg": f"已向工单 {req.work_order_id} 的负责人发送提醒：{req.message}"}


# ==========================================
# 职责三：复查处理结果，若未解决则重新派单
# ==========================================

@router.get("/reviews/pending")
def get_orders_for_review():
    """获取运维人员已完工（CompleteTime不为空）但审核状态为'未通过'的工单，等待管理员复查"""
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = """
            SELECT W.*, U.RealName as MaintainerName, A.Content as AlarmContent
            FROM WorkOrder W
            JOIN UserAccount U ON W.MaintainerId = U.UserId
            JOIN Alarm A ON W.AlarmId = A.AlarmId
            WHERE W.CompleteTime IS NOT NULL 
            AND W.ReviewStatus = N'未通过' 
            AND A.ProcessStatus != N'已结案' -- 确保只查询还没最终结案的
        """
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()


@router.post("/review/audit")
def audit_work_order(req: WorkOrderReviewRequest):
    """
    功能：复查运维结果。
    逻辑：
    - 如果通过：将工单 ReviewStatus 置为 '通过'，告警 ProcessStatus 保持 '已结案'。
    - 如果不通过（故障未解决）：
      1. 工单备注里追加驳回原因。
      2. 关键：将关联的 Alarm 状态重置为 '未处理' (这样又会回到待派单列表，实现“重新派单”)。
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        if req.is_passed:
            # 1. 审核通过
            sql = """
                UPDATE WorkOrder 
                SET ReviewStatus = N'通过', 
                    ResultDesc = ResultDesc + N' [管理员审核通过]'
                WHERE WorkOrderId = %d
            """
            cursor.execute(sql, (req.work_order_id,))
            # 关键：同步将告警设为已结案
            sql_alarm = """
                        UPDATE Alarm
                        SET ProcessStatus = N'已结案'
                        WHERE AlarmId = (SELECT AlarmId FROM WorkOrder WHERE WorkOrderId = %d) \
                        """
            cursor.execute(sql_alarm, (req.work_order_id,))
            msg = "审核通过，工单流程结束"

        else:
            # 2. 审核不通过（故障未解决 -> 重新派单）
            # 更新工单备注
            sql_wo = """
                UPDATE WorkOrder 
                SET ResultDesc = ResultDesc + N' [审核驳回: ' + %s + N']'
                WHERE WorkOrderId = %d
            """
            cursor.execute(sql_wo, (req.review_comments, req.work_order_id))

            # 重置告警状态为 '未处理'，以便重新进入派单池
            sql_alarm = """
                UPDATE Alarm 
                SET ProcessStatus = N'未处理'
                WHERE AlarmId = (SELECT AlarmId FROM WorkOrder WHERE WorkOrderId = %d)
            """
            cursor.execute(sql_alarm, (req.work_order_id,))
            msg = "审核驳回，告警已重置为未处理状态，请重新派单"

        conn.commit()
        return {"msg": msg}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()