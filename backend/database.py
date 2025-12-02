# backend/database.py
import pymssql

# 数据库配置
DB_SETTINGS = {
    "server": "127.0.0.1",
    "user": "sa",
    "password": "123456888", # ⚠️ 记得填你的密码
    "database": "SmartEnergyDB",
    # "charset": "CP936"
}

def get_conn():
    """获取数据库连接的公共函数"""
    return pymssql.connect(**DB_SETTINGS)