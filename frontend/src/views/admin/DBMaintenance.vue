<template>
  <div class="admin-content">
    <el-card shadow="never" header="运行状态">
      <el-row>
        <el-col :span="8"><el-statistic title="活跃连接" :value="dbStats.active_connections" /></el-col>
        <el-col :span="8"><el-statistic title="数据库大小" :value="dbStats.total_size" /></el-col>
        <el-col :span="8"><el-button icon="Refresh" @click="fetchStats">刷新</el-button></el-col>
      </el-row>
    </el-card>

    <el-card shadow="never" header="数据备份" style="margin-top: 20px;">
      <el-alert title="高危：恢复操作会踢出所有当前登录用户！" type="warning" show-icon />
      <div style="margin-top: 20px;">
        <el-button type="primary" @click="doBackup">立即备份数据库 (.bak)</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { reactive, onMounted } from 'vue'
import axios from '../../utils/request'
import { ElMessage } from 'element-plus'

const dbStats = reactive({ active_connections: 0, total_size: '0 MB' })
const fetchStats = async () => {
  try {
    // ✅ 修改：res 已经是后端数据，不需要 .data
    const res = await axios.get('/api/admin/monitor/stats')
    Object.assign(dbStats, res)
  } catch (error) {
    console.error('获取统计失败', error)
  }
}
const doBackup = async () => {
  try {
    // ✅ 修改：res 已经是后端数据
    const res = await axios.post('/api/admin/maintenance/backup', {})
    ElMessage.success(`备份成功至：${res.path}`)
  } catch (error) {
    ElMessage.error('备份失败，请检查权限')
  }
}
onMounted(fetchStats)
</script>