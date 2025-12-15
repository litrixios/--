# 启动

创建你自己的虚拟环境或者不创建

依次输入

```
pip install -r requirements.txt

cd frontend

npm install
```

之后需要先启动后端

在根目录下

```
uvicorn backend.main:app --reload
```

在frontend目录下

```
npm run dev
```



---------------------------------------------------------------------------------------------

# 介绍

#### 1. 核心骨架：`src/layout/Layout.vue`

**左边**是侧边栏（Sidebar）：放菜单。

**右边**是主内容区（Main）：**这里是空的！** 它是通过 `<router-view />` 这个标签来占位的。

**原理**：当你点击左边菜单时，Vue 会把右边的内容“替换”成对应的页面文件（比如 `DispatchCenter.vue`）。

#### 2. 指路地图：`src/router/index.js`

这是整个系统的“导航图”。它决定了：

访问 URL `/dashboard` -> 显示 `Dashboard.vue`

访问 URL `/dispatch-center` -> 显示 `DispatchCenter.vue`

**最重要的功能（路由守卫）**：它会检查 `meta: { role: '...' }`。如果你是“运维人员”，想强行访问 `/dispatch-center`（属于管理员），路由守卫会把你拦住。

#### 3. 身份验证：`src/views/Login.vue`

这是大门。目前我们是“模拟登录”，直接把角色写进了浏览器的 `localStorage` 里。

---------------------------------------------------------------------------------------------

# 示例

我们如果要加一个能源管理员的角色

#### 第一步：创建页面文件

在 `src/views/` 下新建文件夹 `energy`，然后新建 `EnergyMonitor.vue`。

<template>
  <div style="padding: 20px;">
    <h2>📊 全厂能耗实时监控</h2>
    <el-card>
      <p>今日用电量：12000 kWh</p>
    </el-card>
  </div>
</template>

#### 第二步：注册路由 (告诉系统有这个页面)

打开 `src/router/index.js`，在 `children` 数组里加一段：

{
  path: 'energy-monitor',
  component: () => import('../views/energy/EnergyMonitor.vue'),
  meta: { 
    title: '能耗监控', 
    role: '能源管理员'  // 👈 关键：只有能源管理员能进！
  }
}

#### 第三步：修改菜单 (让他在侧边栏看到)

打开 `src/layout/Layout.vue`，在 `<el-menu>` 标签里增加一个菜单项：

<el-menu-item v-if="role === '能源管理员'" index="/energy-monitor">
  <el-icon><DataLine /></el-icon> <span>能耗监控大屏</span>
</el-menu-item>