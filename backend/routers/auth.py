# backend/routers/auth.py
import hashlib
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException
from jose import jwt
from backend.database import get_conn
from backend.models import LoginRequest, LoginResponse
# 引入配置
from backend.deps import SECRET_KEY, ALGORITHM

router = APIRouter(tags=["认证系统"])


@router.post("/api/login", response_model=LoginResponse)
def login(req: LoginRequest):
    conn = get_conn()
    cursor = conn.cursor(as_dict=True)
    try:
        # 1. 查用户状态
        sql = """
            SELECT UserId, RealName, PasswordHash, RoleCode, 
                   IsLocked, FailedLoginCount 
            FROM UserAccount 
            WHERE UserName = %s
        """
        cursor.execute(sql, (req.username,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=400, detail="用户不存在")

        # 【安全功能1：检查锁定状态】
        if user['IsLocked']:
            raise HTTPException(status_code=403, detail="账号已被锁定，请联系管理员")

        # 2. 密码比对
        input_pwd_hash = hashlib.sha256(req.password.encode('utf-8')).digest()
        db_pwd_hash = user['PasswordHash']

        if input_pwd_hash != db_pwd_hash:
            # 【安全功能1：登录失败计数】
            new_count = (user['FailedLoginCount'] or 0) + 1
            is_locked = 1 if new_count >= 5 else 0

            # 更新数据库
            update_sql = """
                UPDATE UserAccount 
                SET FailedLoginCount = %s, IsLocked = %s, LastFailedTime = GETDATE()
                WHERE UserId = %s
            """
            cursor.execute(update_sql, (new_count, is_locked, user['UserId']))
            conn.commit()

            msg = "密码错误"
            if is_locked:
                msg += "，错误次数过多，账号已锁定"
            else:
                msg += f"，再错 {5 - new_count} 次将被锁定"

            raise HTTPException(status_code=400, detail=msg)

        # 3. 登录成功：重置计数
        cursor.execute("UPDATE UserAccount SET FailedLoginCount = 0 WHERE UserId = %s", (user['UserId'],))
        conn.commit()

        # 【安全功能2：生成带30分钟过期的 JWT Token】
        expire = datetime.utcnow() + timedelta(minutes=30)
        token_data = {
            "sub": user['UserName'],
            "user_id": user['UserId'],
            "role_code": user['RoleCode'],
            "exp": expire
        }
        token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

        return LoginResponse(
            token=token,
            user_id=user['UserId'],
            real_name=user['RealName'],
            role_code=user['RoleCode']
        )

    finally:
        conn.close()