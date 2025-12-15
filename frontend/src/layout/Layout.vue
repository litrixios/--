<template>
  <div class="app-wrapper">
    <el-aside width="220px" class="sidebar">
      <div class="logo">智慧能源管理</div>
      <el-menu router background-color="#304156" text-color="#fff" active-text-color="#409EFF">

        <el-menu-item index="/dashboard">首页</el-menu-item>

        <el-menu-item v-if="role === 'WorkOrderAdmin'" index="/dispatch-center">
          调度中心 (审核/派单)
        </el-menu-item>

        <el-menu-item v-if="role === 'Maintainer'" index="/my-tasks">
          我的维修任务
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

const role = ref(localStorage.getItem('role') || '')
const router = useRouter()

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