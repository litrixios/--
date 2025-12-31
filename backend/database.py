# backend/database.py
import pymssql

# 数据库配置
DB_SETTINGS = {
    "server": "127.0.0.1",
    "user": "sa",
    "password": "zhouji2004", # ⚠️ 记得填你的密码
    "database": "SmartEnergyDB",
    # "charset": "CP936"
}

def get_conn():
    """获取数据库连接的公共函数"""
    return pymssql.connect(**DB_SETTINGS)


# ==========================================
# 👇 新增：自我测试功能
# ==========================================
if __name__ == "__main__":
    print(f"🔌 正在尝试连接数据库 [{DB_SETTINGS['database']}]...")

    conn = None
    try:
        # 1. 尝试获取连接
        conn = get_conn()
        print("✅ 连接成功！握手正常。")

        # 2. 尝试查询版本号（确保能执行 SQL）
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        row = cursor.fetchone()
        if row:
            # 打印版本信息的前50个字符
            print(f"ℹ️  数据库版本: {str(row[0])[:50]}...")

    except Exception as e:
        print("\n❌ 连接失败！")
        print(f"错误信息: {e}")
        print("提示：请检查 1.SQL服务是否开启 2.密码是否正确 3.数据库名是否写对")

    finally:
        if conn:
            conn.close()
            print("👋 测试结束，连接已关闭。")