# backend/main.py
import uvicorn
from fastapi import FastAPI

# 导入拆分出去的模块
from backend.routers import energy_manager
from backend.routers import operator
from backend.routers import admin
from backend.routers import work_order_admin

app = FastAPI(title="智慧能源管理系统 API")

# 注册路由器
# 这样 manager.py 里的接口就正式生效了
app.include_router(energy_manager.router)
app.include_router(operator.router)
app.include_router(admin.router)
app.include_router(work_order_admin.router)

@app.get("/")
def root():
    return {"message": "系统正在运行中..."}

if __name__ == "__main__":
    # 注意：因为文件夹结构变了，运行时要在根目录运行，或者在 PyCharm 配置好 Working Directory
    uvicorn.run(app, host="127.0.0.1", port=8000)