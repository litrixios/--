# backend/deps.py
from fastapi import Depends, HTTPException, Header
from jose import jwt, JWTError
from typing import Optional

# 配置密钥和过期时间
SECRET_KEY = "your_secret_key_here"  # 请改为复杂的随机字符串
ALGORITHM = "HS256"


# 1. 验证 Token 并获取当前用户信息
def get_current_user_claims(token: str = Header(..., alias="Authorization")):
    # 前端传来的 header 通常是 "Bearer <token>"，这里做个简单处理
    if token.startswith("Bearer "):
        token = token.split(" ")[1]

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload  # 返回包含 user_id, role_code, exp 的字典
    except JWTError:
        raise HTTPException(status_code=401, detail="Token 无效或已过期")


# 2. RBAC 权限依赖生成器
def require_role(allowed_roles: list):
    def role_checker(claims: dict = Depends(get_current_user_claims)):
        user_role = claims.get("role_code")
        if user_role not in allowed_roles:
            raise HTTPException(status_code=403, detail="权限不足")
        return claims

    return role_checker