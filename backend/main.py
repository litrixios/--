# backend/main.py
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 导入路由
from backend.routers import energy_manager, analyst
from backend.routers import operator
from backend.routers import admin
from backend.routers import work_order_admin
from backend.routers import auth
from backend.routers import management

app = FastAPI(title="智慧能源管理系统 API")

# 跨域配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由器
app.include_router(energy_manager.router)
app.include_router(operator.router)
app.include_router(admin.router)
app.include_router(work_order_admin.router)
app.include_router(analyst.router)
app.include_router(auth.router)
app.include_router(management.router)

@app.get("/")
def root():
    return {"message": "系统正在运行中..."}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)