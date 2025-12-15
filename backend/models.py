# backend/models.py
from pydantic import BaseModel

# ==========================================
# 登录认证模型
# ==========================================

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    token: str      # 暂时用假 token，比如 UUID
    user_id: int
    real_name: str
    role_code: str  # 前端根据这个跳转不同页面

# 能源管理员同意或驳回请求
class AuditRequest(BaseModel):
    data_id: int
    is_valid: bool
    notes: str = ""


# 新增：运维人员“接单”请求 (创建一个工单)
class WorkOrderCreateRequest(BaseModel):
    alarm_id: int       # 针对哪条告警
    maintainer_id: int  # 谁来修 (对应 UserAccount 的 UserId)

# 新增：运维人员“完工”请求 (填写处理结果)
class WorkOrderFinishRequest(BaseModel):
    work_order_id: int  # 工单ID
    result_desc: str    # 处理结果描述
    attachment_path: str = None # 图片路径 (模拟上传)

# ==========================================
# 系统管理员 - 用户管理模型
# ==========================================

# 1. 添加新用户
class UserAddRequest(BaseModel):
    user_name: str    # 登录账号 (比如 "zhangsan")
    real_name: str    # 真实姓名 (比如 "张三丰")
    password: str     # 初始密码
    phone: str = None
    role_code: str    # 角色 (能源管理员/运维人员...)

# 2. 修改用户信息 (改手机号、角色)
class UserUpdateRequest(BaseModel):
    user_id: int
    phone: str = None
    role_code: str = None

# 3. 锁定/解锁用户
class UserLockRequest(BaseModel):
    user_id: int
    is_locked: bool   # True=锁定, False=解锁

# 4. 重置密码 (管理员强制改密码)
class UserResetPwdRequest(BaseModel):
    user_id: int
    new_password: str

# ==========================================
# 系统管理员 - 规则配置模型
# ==========================================

# 1. 修改告警阈值
class AlarmRuleUpdateRequest(BaseModel):
    device_type: str    # "变压器"
    metric_name: str    # "绕组温度"
    new_threshold: float # 新的阈值，比如 110.5

# 2. 修改电价时段 (这里做个简化，直接更新某一时段的类型)
class PricePolicyUpdateRequest(BaseModel):
    policy_id: int
    new_price_type: str # Sharp/Peak/Flat/Valley

# ==========================================
# 系统管理员 - 运维模型
# ==========================================

class BackupRequest(BaseModel):
    # 备份文件名，例如 "backup_20251214.bak"
    # 如果不填，后端可以自动生成一个带日期的名字
    file_name: str = None

class RestoreRequest(BaseModel):
    # 必须指定要从哪个文件恢复，例如 "D:/DB_Backups/backup_20251214.bak"
    full_path: str

# ==========================================
# 新增：运维管理员 - 告警处理模型
# ==========================================

# 场景：管理员判定该告警为误报，直接关闭，不生成工单
class AlarmDismissRequest(BaseModel):
    alarm_id: int         # 要处理的告警ID
    reason: str = "误报"   # 排除原因，默认为"误报"

# ==========================================
# 新增：运维工单管理员 - 审核与复查模型
# ==========================================

# 1. 复查工单请求
class WorkOrderReviewRequest(BaseModel):
    work_order_id: int
    is_passed: bool       # True=通过(故障已解决), False=驳回(故障未解决)
    review_comments: str = "" # 审核意见

# 2. 催单请求 (可选，如果只需通过ID催单)
class RemindRequest(BaseModel):
    work_order_id: int
    message: str = "工单处理超时，请尽快响应！"