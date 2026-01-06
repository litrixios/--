<template>
  <div class="admin-content">
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card shadow="never" header="告警阈值配置">
          <el-form label-width="100px">
            <el-form-item label="设备类型"><el-input v-model="alarmForm.device_type" /></el-form-item>
            <el-form-item label="监控指标"><el-input v-model="alarmForm.metric_name" /></el-form-item>
            <el-form-item label="新阈值"><el-input-number v-model="alarmForm.new_threshold" /></el-form-item>
            <el-button type="primary" @click="submitAlarmUpdate">保存配置</el-button>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never" header="电价时段划分">
          <el-table :data="pricePolicies" size="small">
            <el-table-column prop="TimeStart" label="开始时间" />
            <el-table-column prop="PriceType" label="类型">
              <template #default="scope">
                <el-select v-model="scope.row.PriceType" size="small" @change="updatePrice(scope.row)">
                  <el-option label="尖峰" value="Sharp" /><el-option label="高峰" value="Peak" />
                  <el-option label="平段" value="Flat" /><el-option label="低谷" value="Valley" />
                </el-select>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import axios from '../../utils/request'
import { ElMessage } from 'element-plus'

const pricePolicies = ref([])
const alarmForm = reactive({ device_type: 'Transformer', metric_name: 'Temperature', new_threshold: 80 })

const fetchPricePolicies = async () => {
  try {
    const res = await axios.get('/api/admin/price-policy/list')
    // 直接赋值 res，不要写 .data
    pricePolicies.value = res
    console.log("检查数据结构:", res) // 看看控制台打印的是不是数组
  } catch (error) {
    console.error('获取失败', error)
  }
}
const submitAlarmUpdate = async () => {
  try {
    await axios.post('/api/admin/alarm-rule/update', alarmForm)
    ElMessage.success('阈值已更新')
  } catch (error) {
    ElMessage.error('保存失败')
  }
}
const updatePrice = async (row) => {
  try {
    // ✅ 注意：确认后端的 policy_id 和 new_price_type 命名是否与此一致
    await axios.post('/api/admin/price-policy/update', {
      policy_id: row.PolicyId,
      new_price_type: row.PriceType
    })
    ElMessage.success('电价策略已更新')
  } catch (error) {
    ElMessage.error('更新失败')
  }
}
onMounted(fetchPricePolicies)
</script>