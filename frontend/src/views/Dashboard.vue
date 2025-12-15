<template>
  <div class="dashboard-container">
    <el-card>
      <h2>👋 欢迎来到智慧能源管理系统</h2>
      <p>当前登录角色：{{ role }}</p>
      <div class="tips">
        <p v-if="role === '运维工单管理员'">👉 请点击左侧 <b>[调度中心]</b> 进行工单管理</p>
        <p v-if="role === '运维人员'">👉 请点击左侧 <b>[我的维修任务]</b> 查看待办</p>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const role = ref(localStorage.getItem('role') || '未知用户')
</script>

<style scoped>
.dashboard-container { padding: 20px; }
.tips { margin-top: 20px; color: #666; }
</style>