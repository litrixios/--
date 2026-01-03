<template>
  <div class="app-wrapper">
    <el-aside width="220px" class="sidebar">
      <div class="logo">智慧能源管理</div>
      <el-menu router background-color="#304156" text-color="#fff" active-text-color="#409EFF">

        <el-menu-item index="/dashboard">首页</el-menu-item>

        <el-menu-item v-if="role === 'EnergyAdmin'" index="/energy-manager">
          能源管理中心
        </el-menu-item>

        <el-menu-item v-if="role === 'Manager' || role === 'manager'" index="/manager/overview">
          管理层驾驶舱
        </el-menu-item>

        <template v-if="role === 'Admin'">
          <el-menu-item index="/system/users">用户账号维护</el-menu-item>
          <el-menu-item index="/system/config">参数策略配置</el-menu-item>
          <el-menu-item index="/system/db">数据库运维</el-menu-item>
        </template>

        <el-menu-item v-if="role === 'WorkOrderAdmin'" index="/dispatch-center">
          调度中心 (审核/派单)
        </el-menu-item>

        <el-menu-item v-if="role === 'Manager'" index="/screen-bg">
          大屏展示
        </el-menu-item>

        <el-menu-item v-if="role === 'Maintainer'" index="/my-tasks">
          我的维修任务
        </el-menu-item>

        <el-menu-item v-if="role === '数据分析师' || role === 'Analyst'" index="/analysis/report">
          数据挖掘与深度分析
        </el-menu-item>

        <el-menu-item @click="logout">退出登录</el-menu-item>
      </el-menu>
    </el-aside>

    <el-main>
      <router-view />
    </el-main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// 兼容读取：防止登录页存的是 role_code 而这里读的是 role
const role = ref(localStorage.getItem('role') || localStorage.getItem('role_code') || '')

const logout = () => {
  localStorage.clear()
  router.push('/login')
}
</script>

<style scoped>
.app-wrapper { display: flex; height: 100vh; }
.sidebar { background-color: #304156; }
.logo { color: white; padding: 20px; font-weight: bold; font-size: 18px; }
</style>