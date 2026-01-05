<template>
  <div class="dispatch-container">
    <h2>⚡ 运维调度中心</h2>

    <el-tabs v-model="activeTab" type="border-card">

      <el-tab-pane label="待处理告警" name="pending">
        <el-table :data="pendingAlarms" style="width: 100%" v-loading="loading">
          <el-table-column prop="AlarmId" label="ID" width="60" />
          <el-table-column prop="OccurTime" label="时间" width="180" />
          <el-table-column prop="Content" label="告警内容" />
          <el-table-column prop="AssetName" label="相关设备" width="150" />
          <el-table-column prop="AlarmLevel" label="等级" width="80" fixed="right">
            <template #default="scope">
              <el-tag :type="scope.row.AlarmLevel === '高' ? 'danger' : 'warning'">
                {{ scope.row.AlarmLevel }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="scope">
              <el-button size="small" type="primary" @click="openDispatch(scope.row)">派单</el-button>
              <el-button size="small" type="info" @click="dismissAlarm(scope.row)">误报忽略</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="待复查工单" name="review">
        <el-table :data="pendingReviews" style="width: 100%" v-loading="loading">
          <el-table-column prop="WorkOrderId" label="工单ID" width="80" />
          <el-table-column prop="MaintainerName" label="运维人员" width="100" />
          <el-table-column prop="DispatchTime" label="派单时间" width="160" />
          <el-table-column prop="CompleteTime" label="完工时间" width="160" />
          <el-table-column prop="ResultDesc" label="运维结果描述" />
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="scope">
              <el-button size="small" type="success" @click="auditOrder(scope.row, true)">审核通过</el-button>
              <el-button size="small" type="danger" @click="auditOrder(scope.row, false)">驳回重派</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="工单进度监控" name="monitor">
        <p class="monitor-tip">当前显示超过 <span class="highlight-time">24 小时</span> 未完工的待处理工单。</p>
        <el-table :data="monitoringOrders" style="width: 100%" v-loading="loading">
          <el-table-column prop="WorkOrderId" label="工单ID" width="80" />
          <el-table-column prop="MaintainerName" label="运维人员" width="100" />
          <el-table-column prop="DispatchTime" label="派单时间" width="160" />
          <el-table-column prop="AlarmContent" label="告警内容" />
          <el-table-column label="操作" width="100" fixed="right">
            <template #default="scope">
              <el-button size="small" type="warning" @click="remindMaintainer(scope.row)">催办提醒</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

    </el-tabs>

    <el-dialog v-model="dispatchDialogVisible" title="派发运维工单" width="400px">
      <p>告警 ID: <strong>{{ currentAlarm ? currentAlarm.AlarmId : '' }}</strong></p>
      <p>告警内容: {{ currentAlarm ? currentAlarm.Content : '' }}</p>

      <el-select v-model="selectedMaintainer" placeholder="请选择运维人员" style="width: 100%; margin-top: 15px;">
        <el-option
            v-for="item in maintainers"
            :key="item.UserId"
            :label="item.RealName"
            :value="item.UserId"
        />
      </el-select>
      <template #footer>
        <el-button @click="dispatchDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmDispatch">确认派单</el-button>
      </template>
    </el-dialog>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios' // 确保已安装: npm install axios
import { ElMessage, ElMessageBox } from 'element-plus'

// --- 状态变量 ---
const activeTab = ref('pending')
const loading = ref(false)
const pendingAlarms = ref([]) // 待处理告警
const pendingReviews = ref([]) // 待复查工单
const monitoringOrders = ref([]) // 监控工单
const maintainers = ref([]) // 运维人员列表

// 弹窗相关
const dispatchDialogVisible = ref(false)
const currentAlarm = ref(null)
const selectedMaintainer = ref(null)

// --- 修复点：直接配置 Axios 实例 ---
// 你的后端运行在 localhost:8000，且此页面接口前缀大多为 /api/wo-admin
const request = axios.create({
  baseURL: 'http://127.0.0.1:8000',
  timeout: 5000
})
request.interceptors.request.use(config => {
  // 从本地存储（localStorage）获取 Token
  // 注意：请确认你登录成功后保存 Token 的键名是 'token' 还是 'auth_token'
  const token = localStorage.getItem('token');

  if (token) {
    // 这里的格式必须符合后端要求，通常是 "Bearer <token>"
    config.headers['Authorization'] = `Bearer ${token}`;
  }

  return config;
}, error => {
  return Promise.reject(error);
})
// --- 方法：数据加载 ---
const loadData = async () => {
  loading.value = true
  try {
    // 并发请求所有需要的数据，提高加载速度
    const [alarmsRes, reviewsRes, maintainersRes, monitorRes] = await Promise.all([
      request.get('/api/wo-admin/alarms/pending'),
      request.get('/api/wo-admin/reviews/pending'),
      request.get('/api/wo-admin/maintainers'),
      request.get('/api/wo-admin/monitor?overdue_hours=24')
    ])

    pendingAlarms.value = alarmsRes.data
    pendingReviews.value = reviewsRes.data
    maintainers.value = maintainersRes.data
    monitoringOrders.value = monitorRes.data

  } catch (error) {
    console.error('数据加载失败:', error)
    // 增加更友好的错误提示
    const errorMsg = error.response?.data?.detail || '无法连接到服务器，请确认后端(端口8000)已启动。'
    ElMessage.error(errorMsg)
  } finally {
    loading.value = false
  }
}

// --- 业务逻辑：忽略误报 ---
const dismissAlarm = async (row) => {
  try {
    await ElMessageBox.confirm(`确定要将告警 ID ${row.AlarmId} 标记为误报并关闭吗？`, '警告', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })

    const { value: reason } = await ElMessageBox.prompt(
        '请输入忽略该告警的具体原因：',
        '误报忽略',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          inputValidator: (value) => value ? true : '原因不能为空',
        }
    )

    await request.post('/api/wo-admin/alarm/dismiss', {
      alarm_id: row.AlarmId,
      reason: reason
    })
    ElMessage.success('该告警已确认为误报并关闭。')
    loadData() // 刷新
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('操作已取消或失败')
  }
}

// --- 业务逻辑：派单 ---
const openDispatch = (row) => {
  currentAlarm.value = row
  selectedMaintainer.value = null
  dispatchDialogVisible.value = true
}

const confirmDispatch = async () => {
  if (!selectedMaintainer.value) return ElMessage.warning('请选择运维人员')

  try {
    await request.post('/api/wo-admin/dispatch', {
      alarm_id: currentAlarm.value.AlarmId,
      maintainer_id: selectedMaintainer.value
    })

    ElMessage.success(`告警 ${currentAlarm.value.AlarmId} 派单成功！`)
    dispatchDialogVisible.value = false
    loadData()
  } catch (error) {
    console.error(error)
    ElMessage.error(error.response?.data?.detail || '派单失败')
  }
}

// --- 业务逻辑：催办 ---
const remindMaintainer = async (row) => {
  try {
    const message = `工单 ${row.WorkOrderId} 已超过 24 小时未处理，请尽快响应。`
    await request.post('/api/wo-admin/remind', {
      work_order_id: row.WorkOrderId,
      message: message
    })
    ElMessage.success(`已向运维人员 ${row.MaintainerName} 发送催办提醒。`)
  } catch (error) {
    ElMessage.error('发送提醒失败')
  }
}

// --- 业务逻辑：审核工单 ---
const auditOrder = async (row, isPassed) => {
  let comment = ""
  try {
    if (!isPassed) {
      const { value } = await ElMessageBox.prompt(`驳回工单 ${row.WorkOrderId}，请说明原因：`, '工单驳回', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'error',
        inputValidator: (value) => value ? true : '驳回原因不能为空',
      })
      comment = value
    }

    await request.post('/api/wo-admin/review/audit', {
      work_order_id: row.WorkOrderId,
      is_passed: isPassed,
      review_comments: comment
    })

    if (isPassed) {
      ElMessage.success('工单审核通过，已结案。')
    } else {
      ElMessage.warning('工单已驳回！关联告警已重置。')
    }
    loadData()

  } catch (e) {
    if (e !== 'cancel') ElMessage.error('审核操作失败')
  }
}

// --- 生命周期 ---
onMounted(() => {
  loadData()
})
</script>

<style scoped>
.dispatch-container { padding: 20px; background-color: #fff; min-height: 80vh; }
.monitor-tip {
  margin-bottom: 15px;
  font-size: 14px;
  color: #606266;
  background: #fdf6ec;
  padding: 8px 15px;
  border-radius: 4px;
}
.highlight-time {
  font-weight: bold;
  color: #E6A23C;
}
h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>