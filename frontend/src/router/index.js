import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Layout from '../layout/Layout.vue'
import ManagerOverview from '../views/manager/ManagerOverview.vue'

const routes = [
  { path: '/login', component: Login },
  {
    path: '/',
    component: Layout, // 统一使用这一个主布局
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        component: () => import('../views/Dashboard.vue'),
        meta: { title: '首页' }
      },

      // --- 系统管理员功能 (Admin) ---
      // 将 path 改为相对路径，统一挂载在主侧边栏下
      {
        path: 'system/users',
        component: () => import('../views/admin/UserManagement.vue'),
        meta: { title: '用户管理', role: 'Admin' }
      },
      {
        path: 'system/config',
        component: () => import('../views/admin/ConfigManagement.vue'),
        meta: { title: '参数配置', role: 'Admin' }
      },
      {
        path: 'system/db',
        component: () => import('../views/admin/DBMaintenance.vue'),
        meta: { title: '数据库运维', role: 'Admin' }
      },

      // --- 运维工单管理员专属页面 ---
      {
        path: 'dispatch-center',
        component: () => import('../views/wo-admin/DispatchCenter.vue'),
        meta: { title: '调度中心', role: 'WorkOrderAdmin' }
      },

      // --- 运维人员专属页面 ---
      {
        path: 'my-tasks',
        component: () => import('../views/operator/MyTasks.vue'),
        meta: { title: '我的工单', role: 'Maintainer' }
      },
      // --- 数据分析师专属页面 (Analyst) ---
      {
        path: 'analysis/report',
        component: () => import('../views/analyst/AnalystView.vue'), // 确保路径正确
        meta: { title: '数据深度分析', role: 'Analyst' } // 角色名需匹配数据库
      },

      {
        path: 'manager/overview',
        name: 'ManagerOverview',
        component: ManagerOverview,
        meta: {
            title: '管理层驾驶舱',
            icon: 'Monitor',  // 如果你有用图标组件
            roles: ['manager'] // 权限控制
        }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：逻辑保持不变
router.beforeEach((to, from, next) => {
  const userRole = localStorage.getItem('role')

  if (to.path === '/login') return next()

  if (!userRole) {
    return next('/login')
  }

  // 检查该页面或父级页面是否有角色限制
  const requiredRole = to.matched.some(record => record.meta.role)
      ? to.matched.find(record => record.meta.role).meta.role
      : null;

  if (requiredRole && requiredRole !== userRole) {
    console.warn(`权限不足: 需要 ${requiredRole}, 当前为 ${userRole}`)
    alert('无权访问该页面')
    return next('/')
  }

  next()
})

export default router