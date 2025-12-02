# backend/main.py
import uvicorn
from fastapi import FastAPI

# 导入拆分出去的模块
from backend.routers import energymanager

app = FastAPI(title="智慧能源管理系统 API")

# 注册路由器
# 这样 manager.py 里的接口就正式生效了
app.include_router(energymanager.router)
# app.include_router(admin.router)    # 等写了 admin.py 再取消注释
# app.include_router(operator.router) # 等写了 operator.py 再取消注释

@app.get("/")
def root():
    return {"message": "系统正在运行中..."}

if __name__ == "__main__":
    # 注意：因为文件夹结构变了，运行时要在根目录运行，或者在 PyCharm 配置好 Working Directory
    uvicorn.run(app, host="127.0.0.1", port=8000)