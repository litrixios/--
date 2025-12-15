import pymssql
import os
from fastapi import APIRouter, HTTPException
from datetime import datetime
from backend.database import get_conn
# 导入刚才定义的所有模型
from backend.models import (
    UserAddRequest, UserUpdateRequest, UserLockRequest, UserResetPwdRequest, AlarmRuleUpdateRequest, PricePolicyUpdateRequest, BackupRequest, RestoreRequest
)
from backend.database import DB_SETTINGS

router = APIRouter(prefix="/api/admin", tags=["系统管理员"])


# ==========================================
# 1. 用户列表：查看所有人
# ==========================================
@router.get("/user/list")
def get_user_list(role_filter: str = None):
    """
    功能：获取用户列表。
    参数 role_filter: 可选，比如只看 '运维人员'
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # ⚠️ 注意：千万不要把 PasswordHash 查出来返回给前端！不安全！
        sql = """
            SELECT UserId, UserName, RealName, Phone, RoleCode, 
                   IsLocked, FailedLoginCount, LastFailedTime
            FROM UserAccount
        """

        # 简单的筛选逻辑
        if role_filter:
            # 记得用参数化查询防止注入，这里简单演示用拼接，但加了N前缀
            sql += f" WHERE RoleCode = N'{role_filter}'"

        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()


# ==========================================
# 2. 添加用户 (核心难点：密码加密)
# ==========================================
@router.post("/user/add")
def add_user(request: UserAddRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 💡 核心技巧：使用 SQL Server 的 HASHBYTES 函数
        # 这样 Python 只需要传明文，数据库自己把它变成乱码存进去
        # 'SHA2_256' 是一种标准的加密算法
        sql = """
            INSERT INTO UserAccount 
            (UserName, RealName, PasswordHash, Phone, RoleCode)
            VALUES 
            (%s, %s, HASHBYTES('SHA2_256', %s), %s, %s)
        """

        cursor.execute(sql, (
            request.user_name,
            request.real_name,
            request.password,  # 这里传明文 "123456"
            request.phone,
            request.role_code
        ))
        conn.commit()
        return {"msg": f"用户 {request.user_name} 创建成功"}

    except pymssql.IntegrityError:
        # 如果 UserName 重复了，数据库会报错，这里捕获一下
        conn.rollback()
        raise HTTPException(status_code=400, detail="用户名已存在，请更换")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 3. 修改信息 (手机号/角色)
# ==========================================
@router.post("/user/update")
def update_user(request: UserUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        sql = "UPDATE UserAccount SET Phone = %s, RoleCode = %s WHERE UserId = %d"
        cursor.execute(sql, (request.phone, request.role_code, request.user_id))
        conn.commit()
        return {"msg": "用户信息已更新"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 4. 账号管控 (锁定/解锁)
# ==========================================
@router.post("/user/lock")
def lock_user(request: UserLockRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 如果是解锁 (is_locked=False)，通常还要把“失败次数”清零
        if not request.is_locked:
            sql = "UPDATE UserAccount SET IsLocked = 0, FailedLoginCount = 0 WHERE UserId = %d"
        else:
            sql = "UPDATE UserAccount SET IsLocked = 1 WHERE UserId = %d"

        cursor.execute(sql, (request.user_id,))
        conn.commit()
        status = "锁定" if request.is_locked else "解锁"
        return {"msg": f"用户已{status}"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 5. 密码重置 (忘记密码用)
# ==========================================
@router.post("/user/reset-password")
def reset_password(request: UserResetPwdRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 同样使用 HASHBYTES 进行加密更新
        sql = "UPDATE UserAccount SET PasswordHash = HASHBYTES('SHA2_256', %s) WHERE UserId = %d"
        cursor.execute(sql, (request.new_password, request.user_id))
        conn.commit()
        return {"msg": "密码重置成功"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 6. 配置：修改告警阈值 (影响触发器)
# ==========================================
@router.post("/alarm-rule/update")
def update_alarm_rule(request: AlarmRuleUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 直接更新配置表
        sql = """
            UPDATE AlarmThresholdConfig
            SET ThresholdValue = %s
            WHERE DeviceType = %s AND MetricName = %s
        """
        # 注意中文编码
        cursor.execute(sql, (
            request.new_threshold,
            request.device_type,
            request.metric_name
        ))

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="未找到对应的规则配置，请检查名称是否正确")

        conn.commit()
        return {"msg": f"阈值已更新为 {request.new_threshold}，下次触发告警时生效"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
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
        # 按开始时间排序
        cursor.execute("SELECT * FROM ElectricityPricePolicy ORDER BY TimeStart")
        return cursor.fetchall()
    finally:
        conn.close()


# ==========================================
# 8. 配置：修改电价时段类型 (影响存储过程)
# ==========================================
@router.post("/price-policy/update")
def update_price_policy(request: PricePolicyUpdateRequest):
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 验证输入合法性
        valid_types = ['Sharp', 'Peak', 'Flat', 'Valley']
        if request.new_price_type not in valid_types:
            raise HTTPException(status_code=400, detail="类型必须是 Sharp, Peak, Flat, Valley 之一")

        sql = "UPDATE ElectricityPricePolicy SET PriceType = %s WHERE PolicyId = %d"
        cursor.execute(sql, (request.new_price_type, request.policy_id))

        conn.commit()
        return {"msg": "时段类型已更新，下次计算能耗时生效"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


# ==========================================
# 9. 监控：查看数据库运行状态
# ==========================================
@router.get("/monitor/stats")
def get_db_stats():
    """
    功能：获取数据库大小、连接数等健康状态
    """
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 查询数据库空间占用 (返回 database_name, database_size, unallocated space)
        cursor.execute("EXEC sp_spaceused")
        space_info = cursor.fetchone()  # 结果示例: {'database_size': '16.00 MB', ...}

        # 2. 查询当前有多少个活跃连接 (排除系统后台进程)
        # DB_ID() 会自动获取当前连接的数据库ID
        sql_conn = """
            SELECT COUNT(*) AS ConnectionCount 
            FROM sys.dm_exec_sessions 
            WHERE database_id = DB_ID() AND is_user_process = 1
        """
        cursor.execute(sql_conn)
        conn_info = cursor.fetchone()

        return {
            "db_name": DB_SETTINGS['database'],
            "total_size": space_info.get('database_size'),
            "free_space": space_info.get('unallocated space'),
            "active_connections": conn_info.get('ConnectionCount'),
            "status": "Running"
        }
    finally:
        conn.close()


# ==========================================
# 10. 运维：执行数据库备份
# ==========================================
@router.post("/maintenance/backup")
def backup_database(request: BackupRequest):
    """
    功能：一键备份数据库到指定目录。
    注意：SQL Server 服务账号必须对该目录有写权限。
    """
    conn = get_conn()
    cursor = conn.cursor()
    try:
        # 1. 确定备份路径
        # 建议：在 D 盘建一个文件夹叫 DB_Backups，防止 C 盘权限不足
        backup_dir = "D:\\DB_Backups"

        # 如果文件夹不存在，Python 尝试创建它
        if not os.path.exists(backup_dir):
            os.makedirs(backup_dir)

        # 生成文件名：如果前端没传，就用当前时间
        if request.file_name:
            fname = request.file_name
        else:
            fname = f"SmartEnergy_{datetime.now().strftime('%Y%m%d_%H%M%S')}.bak"

        full_path = os.path.join(backup_dir, fname)

        # 2. 执行备份 SQL
        # FORMAT = 覆盖旧的媒体头，INIT = 覆盖旧文件
        sql = f"BACKUP DATABASE [{DB_SETTINGS['database']}] TO DISK = N'{full_path}' WITH FORMAT, INIT"

        # 备份命令不能放在事务里，所以我们要开启 autocommit
        conn.autocommit(True)
        cursor.execute(sql)

        return {"msg": "备份成功", "path": full_path}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"备份失败: {str(e)}")
    finally:
        conn.close()


# ==========================================
# 11. 运维：执行数据库恢复 (高危操作！)
# ==========================================
@router.post("/maintenance/restore")
def restore_database(request: RestoreRequest):
    """
    功能：从备份文件恢复数据库。
    难点：必须先踢掉所有连接，并且不能连着 SmartEnergyDB 操作，必须连 master。
    """
    # ⚠️ 特殊处理：不能用 get_conn()，因为那是连 SmartEnergyDB 的
    # 我们需要手动创建一个连 'master' 库的连接
    master_settings = DB_SETTINGS.copy()
    master_settings['database'] = 'master'

    conn = None
    try:
        conn = pymssql.connect(**master_settings)
        conn.autocommit(True)  # 恢复操作不能在事务中
        cursor = conn.cursor()

        db_name = DB_SETTINGS['database']

        # 1. 踢人！把数据库设为单用户模式，立即回滚所有未完成事务
        # 这一步会强制断开所有正在使用系统的用户（包括上面的 monitor 接口）
        kill_sql = f"ALTER DATABASE [{db_name}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        cursor.execute(kill_sql)

        # 2. 还原！
        # REPLACE = 覆盖现有数据库
        restore_sql = f"RESTORE DATABASE [{db_name}] FROM DISK = N'{request.full_path}' WITH REPLACE"
        cursor.execute(restore_sql)

        # 3. 恢复多人模式
        recover_sql = f"ALTER DATABASE [{db_name}] SET MULTI_USER"
        cursor.execute(recover_sql)

        return {"msg": f"数据库已成功从 {request.full_path} 恢复！"}

    except Exception as e:
        # 如果中间失败了，尽力尝试把数据库设回多用户模式，否则系统就死锁了
        try:
            if conn:
                cursor.execute(f"ALTER DATABASE [{DB_SETTINGS['database']}] SET MULTI_USER")
        except:
            pass
        raise HTTPException(status_code=500, detail=f"严重错误 - 恢复失败: {str(e)}")
    finally:
        if conn:
            conn.close()