<template>
  <div class="task-container">
    <h2>👷 运维工作台</h2>

    <el-tabs v-model="activeTab" type="border-card" @tab-click="handleTabClick">

      <el-tab-pane label="🔥 待处理高危告警" name="alarms">
        <div class="tab-content">
          <el-alert
              title="请及时响应以下高等级告警！接单后将生成工单。"
              type="error"
              :closable="false"
              show-icon
              style="margin-bottom: 20px;"
          />

          <el-table :data="alarmList" style="width: 100%" v-loading="loadingAlarms" stripe border>
            <el-table-column prop="AlarmId" label="ID" width="60" />
            <el-table-column prop="OccurTime" label="发生时间" width="180">
              <template #default="scope">
                {{ formatDate(scope.row.OccurTime) }}
              </template>
            </el-table-column>
            <el-table-column prop="AlarmContent" label="告警内容" />
            <el-table-column prop="DeviceName" label="关联设备" width="150" />
            <el-table-column prop="AlarmLevel" label="等级" width="80">
              <template #default>
                <el-tag type="danger">高</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120">
              <template #default="scope">
                <el-button
                    type="primary"
                    size="small"
                    @click="handleDispatch(scope.row)"
                >
                  立即接单
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

      <el-tab-pane label="📝 完工汇报" name="complete">
        <div class="form-wrapper">
          <el-alert
              title="现场处理完毕后，请在此填写结果并关闭工单。"
              type="info"
              show-icon
              style="margin-bottom: 20px;"
          />

          <el-form :model="finishForm" label-width="120px" ref="finishFormRef">
            <el-form-item label="工单 ID" required>
              <el-input-number v-model="finishForm.work_order_id" :min="1" placeholder="请输入工单ID" />
              <div class="tips">（注：请输入您接单后生成的 WorkOrderId）</div>
            </el-form-item>

            <el-form-item label="处理结果" required>
              <el-input
                  v-model="finishForm.result_desc"
                  type="textarea"
                  rows="4"
                  placeholder="请详细描述故障处理过程及结果..."
              />
            </el-form-item>

            <el-form-item label="附件路径">
              <el-input v-model="finishForm.attachment_path" placeholder="例如：/uploads/repair_01.jpg" />
            </el-form-item>

            <el-form-item>
              <el-button type="success" @click="submitComplete" :loading="submitting">
                提交并结案
              </el-button>
            </el-form-item>
          </el-form>
        </div>
      </el-tab-pane>

      <el-tab-pane label="🛠️ 设备台账 & 维保计划" name="assets">
        <div class="tab-content">
          <el-alert
              title="系统根据质保年限自动计算维保建议。"
              type="success"
              :closable="false"
              style="margin-bottom: 20px;"
          />

          <el-table :data="assetList" style="width: 100%" v-loading="loadingAssets" border>
            <el-table-column prop="AssetName" label="设备名称" width="180" />
            <el-table-column prop="Model" label="型号" width="150" />
            <el-table-column prop="InstallTime" label="安装日期" width="150">
              <template #default="scope">
                {{ formatDate(scope.row.InstallTime) }}
              </template>
            </el-table-column>
            <el-table-column prop="WarrantyYears" label="质保(年)" width="100" align="center" />

            <el-table-column prop="MaintenanceTips" label="维保建议">
              <template #default="scope">
                <span v-if="scope.row.MaintenanceTips && scope.row.MaintenanceTips.includes('⚠️')" style="color: red; font-weight: bold;">
                  {{ scope.row.MaintenanceTips }}
                </span>
                <span v-else-if="scope.row.MaintenanceTips && scope.row.MaintenanceTips.includes('ℹ️')" style="color: orange; font-weight: bold;">
                  {{ scope.row.MaintenanceTips }}
                </span>
                <span v-else style="color: green;">
                  {{ scope.row.MaintenanceTips }}
                </span>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

    </el-tabs>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import axios from 'axios' // 假设你已安装 axios: npm install axios
import { ElMessage, ElMessageBox } from 'element-plus'

// --- 状态变量 ---
const activeTab = ref('alarms')
const alarmList = ref([])
const assetList = ref([])
const loadingAlarms = ref(false)
const loadingAssets = ref(false)
const submitting = ref(false)

// 假设当前登录的运维人员 ID (实际项目中应从 localStorage 或 Vuex/Pinia 获取)
const currentMaintainerId = parseInt(localStorage.getItem('userId')) || 1

// 表单数据
const finishForm = reactive({
  work_order_id: null,
  result_desc: '',
  attachment_path: ''
})

// --- API 请求配置 (请根据实际后端地址修改 baseURL) ---
const request = axios.create({
  baseURL: 'http://localhost:8000/api/operator', // 假设 FastAPI 运行在 8000 端口
  timeout: 5000
})

// --- 方法：1. 获取高危告警 ---
const fetchAlarms = async () => {
  loadingAlarms.value = true
  try {
    const res = await request.get('/alarm/pending-high')
    alarmList.value = res.data
  } catch (error) {
    console.error(error)
    ElMessage.error('获取告警列表失败')
  } finally {
    loadingAlarms.value = false
  }
}

// --- 方法：2. 接单 (Dispatch) ---
const handleDispatch = (row) => {
  ElMessageBox.confirm(
      `确认接收关于 "${row.DeviceName}" 的高危告警任务吗?`,
      '接单确认',
      { confirmButtonText: '立即接单', cancelButtonText: '取消', type: 'warning' }
  ).then(async () => {
    try {
      // 构造后端需要的 WorkOrderCreateRequest
      const payload = {
        alarm_id: row.AlarmId,
        maintainer_id: currentMaintainerId
      }

      const res = await request.post('/workorder/dispatch', payload)

      ElMessage.success(res.data.msg || '接单成功！')

      // 刷新列表，移除已接单的条目
      fetchAlarms()

      // 自动跳转到完工页面 (可选交互优化)
      // activeTab.value = 'complete'
    } catch (error) {
      console.error(error)
      ElMessage.error(error.response?.data?.detail || '接单失败')
    }
  })
}

// --- 方法：3. 提交完工 (Complete) ---
const submitComplete = async () => {
  if (!finishForm.work_order_id || !finishForm.result_desc) {
    ElMessage.warning('请填写工单ID和处理结果')
    return
  }

  submitting.value = true
  try {
    // 构造后端需要的 WorkOrderFinishRequest
    const payload = {
      work_order_id: finishForm.work_order_id,
      result_desc: finishForm.result_desc,
      attachment_path: finishForm.attachment_path || '无附件'
    }

    const res = await request.post('/workorder/complete', payload)

    ElMessage.success(res.data.msg || '提交成功，告警已关闭')

    // 重置表单
    finishForm.work_order_id = null
    finishForm.result_desc = ''
    finishForm.attachment_path = ''
  } catch (error) {
    console.error(error)
    ElMessage.error(error.response?.data?.detail || '提交失败')
  } finally {
    submitting.value = false
  }
}

// --- 方法：4. 获取设备台账 ---
const fetchAssets = async () => {
  loadingAssets.value = true
  try {
    const res = await request.get('/assets/maintenance-plan')
    assetList.value = res.data
  } catch (error) {
    console.error(error)
    ElMessage.error('获取设备台账失败')
  } finally {
    loadingAssets.value = false
  }
}

// --- 工具：格式化日期 ---
const formatDate = (val) => {
  if (!val) return '-'
  return new Date(val).toLocaleString()
}

// --- 生命周期 ---
onMounted(() => {
  fetchAlarms() // 默认加载告警
})

// 切换 Tab 时按需加载
const handleTabClick = (tab) => {
  if (tab.props.name === 'alarms') {
    fetchAlarms()
  } else if (tab.props.name === 'assets') {
    fetchAssets()
  }
}
</script>

<style scoped>
.task-container {
  padding: 20px;
  background-color: #f5f7fa;
  min-height: 80vh;
}

.tab-content {
  padding: 10px;
}

.form-wrapper {
  max-width: 600px;
  margin: 20px auto;
  padding: 20px;
  background: #fff;
  border-radius: 8px;
}

.tips {
  font-size: 12px;
  color: #999;
  line-height: 1.5;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>