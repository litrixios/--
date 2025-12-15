<template>
  <div class="dispatch-container">
    <h2>⚡ 运维调度中心</h2>

    <el-tabs v-model="activeTab" type="border-card">

      <el-tab-pane label="待处理告警" name="pending">
        <el-table :data="pendingAlarms" style="width: 100%">
          <el-table-column prop="AlarmId" label="ID" width="60" />
          <el-table-column prop="OccurTime" label="时间" width="180" />
          <el-table-column prop="Content" label="告警内容" />
          <el-table-column prop="AlarmLevel" label="等级" width="80">
            <template #default="scope">
              <el-tag :type="scope.row.AlarmLevel === '高' ? 'danger' : 'warning'">
                {{ scope.row.AlarmLevel }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作">
            <template #default="scope">
              <el-button size="small" type="primary" @click="openDispatch(scope.row)">派单</el-button>
              <el-button size="small" type="info" @click="dismissAlarm(scope.row)">误报忽略</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="待复查工单" name="review">
        <el-table :data="pendingReviews" style="width: 100%">
          <el-table-column prop="WorkOrderId" label="工单ID" width="80" />
          <el-table-column prop="MaintainerName" label="运维人员" width="100" />
          <el-table-column prop="ResultDesc" label="处理结果" />
          <el-table-column label="操作">
            <template #default="scope">
              <el-button size="small" type="success" @click="auditOrder(scope.row, true)">通过</el-button>
              <el-button size="small" type="danger" @click="auditOrder(scope.row, false)">驳回</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="dispatchDialogVisible" title="选择运维人员">
      <el-select v-model="selectedMaintainer" placeholder="请选择人员">
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
import request from '../../utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

const activeTab = ref('pending')
const pendingAlarms = ref([])
const pendingReviews = ref([])
const maintainers = ref([])

// 弹窗控制
const dispatchDialogVisible = ref(false)
const currentAlarmId = ref(null)
const selectedMaintainer = ref(null)

// 1. 加载数据
const loadData = async () => {
  // 获取待处理告警
  pendingAlarms.value = await request.get('/api/wo-admin/alarms/pending')
  // 获取待复查工单
  pendingReviews.value = await request.get('/api/wo-admin/reviews/pending')
  // 获取运维人员列表
  maintainers.value = await request.get('/api/wo-admin/maintainers')
}

// 2. 忽略误报
const dismissAlarm = async (row) => {
  try {
    await request.post('/api/wo-admin/alarm/dismiss', {
      alarm_id: row.AlarmId,
      admin_id: 1, // 实际应从登录信息取
      reason: '管理员手动判定为误报'
    })
    ElMessage.success('已忽略该告警')
    loadData()
  } catch (e) {}
}

// 3. 派单逻辑
const openDispatch = (row) => {
  currentAlarmId.value = row.AlarmId
  dispatchDialogVisible.value = true
}

const confirmDispatch = async () => {
  if (!selectedMaintainer.value) return ElMessage.warning('请选择运维人员')

  await request.post('/api/wo-admin/dispatch', {
    alarm_id: currentAlarmId.value,
    maintainer_id: selectedMaintainer.value
  })

  ElMessage.success('派单成功')
  dispatchDialogVisible.value = false
  loadData() // 刷新列表
}

// 4. 审核逻辑
const auditOrder = async (row, isPassed) => {
  let comment = ""
  if (!isPassed) {
    // 如果驳回，需要输入原因
    const { value } = await ElMessageBox.prompt('请输入驳回原因', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
    })
    comment = value
  }

  await request.post('/api/wo-admin/review/audit', {
    work_order_id: row.WorkOrderId,
    is_passed: isPassed,
    review_comments: comment
  })

  ElMessage.success(isPassed ? '已审核通过' : '已驳回并重新进入派单池')
  loadData()
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.dispatch-container { padding: 20px; }
</style>