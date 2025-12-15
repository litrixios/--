import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Layout from '../layout/Layout.vue'

const routes = [
  { path: '/login', component: Login },
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '首页' } },

      // 运维工单管理员专属页面
      {
        path: 'dispatch-center',
        component: () => import('../views/wo-admin/DispatchCenter.vue'),
        meta: { title: '调度中心', role: 'WorkOrderAdmin' }
      },

      // 运维人员专属页面
      {
        path: 'my-tasks',
        component: () => import('../views/operator/MyTasks.vue'),
        meta: { title: '我的工单', role: 'Maintainer' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：简单的权限拦截
router.beforeEach((to, from, next) => {
  const userRole = localStorage.getItem('role') // 假设登录后把角色存在了 localStorage

  if (to.path === '/login') return next()

  if (!userRole) {
    return next('/login') // 没登录这就去登录
  }

  // 检查该页面是否有角色限制
  if (to.meta.role && to.meta.role !== userRole) {
    alert('无权访问该页面')
    return next('/')
  }

  next()
})

export default router