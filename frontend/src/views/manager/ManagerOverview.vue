<template>
  <div class="manager-container">
    <h2 class="page-title">企业能源驾驶舱</h2>

    <el-row :gutter="20" class="mb-4">
      <el-col :span="6">
        <el-card shadow="hover" class="data-card type-power">
          <template #header>
            <div class="card-header">
              <span>本月总用电 (kWh)</span>
              <el-tag type="warning">电</el-tag>
            </div>
          </template>
          <div class="card-value">{{ overviewData.power_kwh }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="data-card type-water">
          <template #header>
            <div class="card-header">
              <span>本月总用水 (m³)</span>
              <el-tag type="primary">水</el-tag>
            </div>
          </template>
          <div class="card-value">{{ overviewData.water_m3 }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="data-card type-gas">
          <template #header>
            <div class="card-header">
              <span>本月总用气 (m³)</span>
              <el-tag type="danger">气</el-tag>
            </div>
          </template>
          <div class="card-value">{{ overviewData.gas_m3 }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="data-card type-pv">
          <template #header>
            <div class="card-header">
              <span>本月光伏发电 (kWh)</span>
              <el-tag type="success">光伏</el-tag>
            </div>
          </template>
          <div class="card-value">{{ overviewData.pv_gen_kwh }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="14">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>💡 降本增效分析 (光伏节省电费)</span>
            </div>
          </template>
          <div ref="revenueChartRef" style="height: 350px;"></div>
        </el-card>
      </el-col>

      <el-col :span="10">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>🔍 能耗溯源 (区域占比)</span>
              <el-select v-model="traceType" size="small" style="width: 100px" @change="fetchTraceData">
                <el-option label="用电" value="Power" />
                <el-option label="用水" value="Water" />
                <el-option label="用气" value="Gas" />
              </el-select>
            </div>
          </template>
          <div ref="traceChartRef" style="height: 350px;"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
// 假设你的文件在 src/views/manager/ 下，utils 在 src/utils/
import request from '../../utils/request'

// --- 数据定义 ---
const overviewData = ref({
  power_kwh: 0,
  water_m3: 0,
  gas_m3: 0,
  pv_gen_kwh: 0
})

const traceType = ref('Power') // 默认溯源电力

// --- ECharts 实例 ---
const revenueChartRef = ref(null)
const traceChartRef = ref(null)
let revenueChart = null
let traceChart = null

// --- API 请求 ---

// 1. 获取总览数据
const fetchOverview = async () => {
  try {
    const res = await request.get('/api/management/dashboard/overview')
    overviewData.value = res
  } catch (error) {
    console.error("获取总览失败", error)
  }
}

// 2. 获取收益分析数据并渲染图表
const fetchRevenueData = async () => {
  try {
    const res = await request.get('/api/management/pv/revenue')
    // res 格式: [{ MonthStr: '2025-10', TotalSelfUse: 1200, SavedMoney: 960 }, ...]

    if (!revenueChart) return

    const months = res.map(item => item.MonthStr)
    const money = res.map(item => item.SavedMoney)

    const option = {
      tooltip: {
        trigger: 'axis',
        formatter: '{b}<br/>节省电费: {c} 元'
      },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: {
        type: 'category',
        data: months
      },
      yAxis: {
        type: 'value',
        name: '金额 (元)'
      },
      series: [
        {
          name: '节省电费',
          type: 'bar',
          barWidth: '40%',
          data: money,
          itemStyle: { color: '#67C23A' }
        },
        {
          name: '趋势',
          type: 'line',
          data: money,
          itemStyle: { color: '#E6A23C' }
        }
      ]
    }
    revenueChart.setOption(option)
  } catch (error) {
    console.error("获取收益数据失败", error)
  }
}

// 3. 获取溯源数据并渲染图表
const fetchTraceData = async () => {
  try {
    const res = await request.get('/api/management/energy/traceability', {
      params: { energy_type: traceType.value }
    })
    // res 格式: [{ AreaName: 'A3厂区', TotalValue: 5000, Percentage: 45.5 }, ...]

    if (!traceChart) return

    const chartData = res.map(item => ({
      value: item.TotalValue,
      name: item.AreaName
    }))

    const option = {
      tooltip: {
        trigger: 'item',
        formatter: '{b}: {c} ({d}%)'
      },
      legend: {
        top: '5%',
        left: 'center'
      },
      series: [
        {
          name: '能耗分布',
          type: 'pie',
          radius: ['40%', '70%'],
          avoidLabelOverlap: false,
          itemStyle: {
            borderRadius: 10,
            borderColor: '#fff',
            borderWidth: 2
          },
          label: {
            show: false,
            position: 'center'
          },
          emphasis: {
            label: {
              show: true,
              fontSize: 20,
              fontWeight: 'bold'
            }
          },
          labelLine: {
            show: false
          },
          data: chartData
        }
      ]
    }
    traceChart.setOption(option)
  } catch (error) {
    console.error("获取溯源数据失败", error)
  }
}

// --- 生命周期 ---
onMounted(async () => {
  // 初始化图表实例
  revenueChart = echarts.init(revenueChartRef.value)
  traceChart = echarts.init(traceChartRef.value)

  // 加载数据
  await fetchOverview()
  await fetchRevenueData()
  await fetchTraceData()

  // 窗口缩放自适应
  window.addEventListener('resize', () => {
    revenueChart.resize()
    traceChart.resize()
  })
})
</script>

<style scoped>
.manager-container {
  padding: 20px;
}
.page-title {
  margin-bottom: 20px;
  font-weight: 600;
  color: #303133;
}
.data-card {
  height: 140px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.card-value {
  font-size: 28px;
  font-weight: bold;
  text-align: center;
  margin-top: 20px;
  color: #409EFF;
}
/* 不同类型的颜色微调 */
.type-power .card-value { color: #E6A23C; }
.type-water .card-value { color: #409EFF; }
.type-gas .card-value { color: #F56C6C; }
.type-pv .card-value { color: #67C23A; }

.mb-4 {
  margin-bottom: 20px;
}
</style>