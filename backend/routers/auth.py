import uuid
import hashlib  # 👈 1. 必须引入这个库
from fastapi import APIRouter, HTTPException
from backend.database import get_conn
from backend.models import LoginRequest, LoginResponse

router = APIRouter(tags=["认证系统"])


@router.post("/api/login", response_model=LoginResponse)
def login(req: LoginRequest):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 查用户
        sql = """
            SELECT UserId, RealName, PasswordHash, RoleCode 
            FROM UserAccount 
            WHERE UserName = %s
        """
        cursor.execute(sql, (req.username,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=400, detail="用户不存在")

        # ========================================================
        # 👇 2. 核心修改：使用 SHA256 算法计算哈希
        # ========================================================

        # 数据库用的是 HASHBYTES('SHA2_256', '密码') -> 返回二进制
        # Python 也要做同样的操作：
        # .encode('utf-8') 把字符串转成字节
        # hashlib.sha256(...) 进行哈希计算
        # .digest() 获取最终的二进制结果 (不要用 hexdigest，那是字符串)
        input_pwd_hash = hashlib.sha256(req.password.encode('utf-8')).digest()

        db_pwd_hash = user['PasswordHash']

        # 3. 比对二进制哈希值
        if input_pwd_hash != db_pwd_hash:
            print(f"比对失败！")
            print(f"前端输入加密后: {input_pwd_hash.hex()}")  # 打印成16进制方便看
            print(f"数据库存储的值: {db_pwd_hash.hex()}")
            raise HTTPException(status_code=400, detail="密码错误")

        # ========================================================

        # 4. 登录成功
        fake_token = str(uuid.uuid4())
        return LoginResponse(
            token=fake_token,
            user_id=user['UserId'],
            real_name=user['RealName'],
            role_code=user['RoleCode']
        )

    finally:
        conn.close()