import pymssql
import os
from fastapi import APIRouter, HTTPException
from datetime import datetime
from backend.database import get_conn, DB_SETTINGS
# 仅导入存在的模型，去掉了导致报错的 PermissionAssignment
from backend.models import (
    UserAddRequest, UserUpdateRequest, UserLockRequest, UserResetPwdRequest,
    AlarmRuleUpdateRequest, PricePolicyUpdateRequest, BackupRequest, RestoreRequest
)

router = APIRouter(prefix="/api/admin", tags=["系统管理员"])

# ==========================================
# 1. 用户列表
# ==========================================
@router.get("/user/list")
def get_user_list(role_filter: str = None):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        sql = "SELECT UserId, UserName, RealName, Phone, RoleCode, IsLocked, FailedLoginCount, LastFailedTime FROM UserAccount"
        if role_filter:
            sql += f" WHERE RoleCode = N'{role_filter}'"
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()

# ==========================================
# 2. 添加用户 (使用 HASHBYTES)
# ==========================================
@router.post("/user/add")
def add_user(request: UserAddRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "INSERT INTO UserAccount (UserName, RealName, PasswordHash, Phone, RoleCode) VALUES (%s, %s, HASHBYTES('SHA2_256', %s), %s, %s)"
        cursor.execute(sql, (request.user_name, request.real_name, request.password, request.phone, request.role_code))
        conn.commit()
        return {"msg": f"用户 {request.user_name} 创建成功"}
    except pymssql.IntegrityError:
        conn.rollback()
        raise HTTPException(status_code=400, detail="用户名已存在")
    finally:
        conn.close()

# ==========================================
# 3. 修改信息
# ==========================================
@router.put("/user/update")
def update_user(request: UserUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE UserAccount SET RealName = %s, Phone = %s, RoleCode = %s WHERE UserId = %d"
        cursor.execute(sql, (request.real_name, request.phone, request.role_code, request.user_id))
        conn.commit()
        return {"msg": "用户信息已更新"}
    finally:
        conn.close()

# ==========================================
# 4. 账号管控
# ==========================================
@router.post("/user/lock")
def lock_user(request: UserLockRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE UserAccount SET IsLocked = %d, FailedLoginCount = 0 WHERE UserId = %d"
        val = 1 if request.is_locked else 0
        cursor.execute(sql, (val, request.user_id))
        conn.commit()
        return {"msg": "操作成功"}
    finally:
        conn.close()

# ==========================================
# 5. 密码重置
# ==========================================
@router.post("/user/reset-password")
def reset_password(request: UserResetPwdRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE UserAccount SET PasswordHash = HASHBYTES('SHA2_256', %s) WHERE UserId = %d"
        cursor.execute(sql, (request.new_password, request.user_id))
        conn.commit()
        return {"msg": "密码重置成功"}
    finally:
        conn.close()

# ==========================================
# 6. 配置：修改告警阈值
# ==========================================
@router.post("/alarm-rule/update")
def update_alarm_rule(request: AlarmRuleUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE AlarmThresholdConfig SET ThresholdValue = %s WHERE DeviceType = %s AND MetricName = %s"
        cursor.execute(sql, (request.new_threshold, request.device_type, request.metric_name))
        conn.commit()
        return {"msg": "阈值已更新"}
    finally:
        conn.close()

# ==========================================
# 7. 配置：获取电价时段列表
# ==========================================
@router.get("/price-policy/list")
def get_price_policies():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        cursor.execute("SELECT * FROM ElectricityPricePolicy ORDER BY TimeStart")
        return cursor.fetchall()
    finally:
        conn.close()

# ==========================================
# 8. 配置：修改电价时段类型
# ==========================================
@router.post("/price-policy/update")
def update_price_policy(request: PricePolicyUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE ElectricityPricePolicy SET PriceType = %s WHERE PolicyId = %d"
        cursor.execute(sql, (request.new_price_type, request.policy_id))
        conn.commit()
        return {"msg": "电价策略已更新"}
    finally:
        conn.close()

# ==========================================
# 9. 监控：数据库运行状态
# ==========================================
@router.get("/monitor/stats")
def get_db_stats():
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        cursor.execute("EXEC sp_spaceused")
        space_info = cursor.fetchone()
        cursor.execute("SELECT COUNT(*) AS ConnectionCount FROM sys.dm_exec_sessions WHERE database_id = DB_ID() AND is_user_process = 1")
        conn_info = cursor.fetchone()
        return {
            "db_name": DB_SETTINGS['database'],
            "total_size": space_info.get('database_size'),
            "active_connections": conn_info.get('ConnectionCount'),
            "status": "Running"
        }
    finally:
        conn.close()

# ==========================================
# 10/11/12. 运维与删除
# ==========================================
@router.post("/maintenance/backup")
def backup_database(request: BackupRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        backup_dir = "D:\\DB_Backups"
        if not os.path.exists(backup_dir): os.makedirs(backup_dir)
        fname = request.file_name or f"SmartEnergy_{datetime.now().strftime('%Y%m%d_%H%M%S')}.bak"
        full_path = os.path.join(backup_dir, fname)
        conn.autocommit(True)
        cursor.execute(f"BACKUP DATABASE [{DB_SETTINGS['database']}] TO DISK = N'{full_path}' WITH FORMAT, INIT")
        return {"msg": "备份成功", "path": full_path}
    finally:
        conn.close()

@router.post("/maintenance/restore")
def restore_database(request: RestoreRequest):
    master_settings = DB_SETTINGS.copy()
    master_settings['database'] = 'master'
    conn = pymssql.connect(**master_settings)
    conn.autocommit(True)
    cursor = conn.cursor()
    db_name = DB_SETTINGS['database']
    try:
        cursor.execute(f"ALTER DATABASE [{db_name}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
        cursor.execute(f"RESTORE DATABASE [{db_name}] FROM DISK = N'{request.full_path}' WITH REPLACE")
        cursor.execute(f"ALTER DATABASE [{db_name}] SET MULTI_USER")
        return {"msg": "数据库还原成功"}
    finally:
        conn.close()

@router.delete("/user/delete/{user_id}")
def delete_user(user_id: int):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM UserAccount WHERE UserId = %d", (user_id,))
        conn.commit()
        return {"msg": "用户已删除"}
    finally:
        conn.close()