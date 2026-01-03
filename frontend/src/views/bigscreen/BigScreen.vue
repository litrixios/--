<template>
  <div class="screen-container">
    <!-- 顶部标题栏 -->
    <div class="screen-header">
      <div class="header-left">
        <h1>🏭 智慧能源管理驾驶舱</h1>
        <div class="time-display">{{ currentTime }}</div>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="refreshAll">刷新数据</el-button>
        <el-button @click="toggleFullScreen">
          {{ isFullScreen ? '退出全屏' : '全屏显示' }}
        </el-button>
      </div>
    </div>

    <!-- 核心指标卡片 -->
    <div class="metrics-section">
      <div class="section-title">核心运行指标</div>
      <el-row :gutter="20" class="metrics-row">
        <el-col :span="3" v-for="(metric, index) in coreMetrics" :key="index">
          <div class="metric-card" :class="metric.trend">
            <div class="metric-icon">{{ metric.icon }}</div>
            <div class="metric-info">
              <div class="metric-value">{{ formatNumber(metric.value) }}</div>
              <div class="metric-label">{{ metric.label }}</div>
              <div class="metric-trend" v-if="metric.trend !== 'neutral'">
                {{ metric.trend === 'up' ? '↑' : '↓' }} {{ metric.change }}
              </div>
            </div>
          </div>
        </el-col>
      </el-row>
    </div>

    <!-- 主要内容区域 -->
    <el-row :gutter="20" class="main-content">
      <!-- 左侧：能源监控 -->
      <el-col :span="14">
        <div class="chart-section">
          <div class="section-header">
            <div class="section-title">能源运行总览</div>
            <div class="time-selector">
              <el-radio-group v-model="timeRange" size="small" @change="fetchEnergyTrend">
                <el-radio-button label="today">今日</el-radio-button>
                <el-radio-button label="week">本周</el-radio-button>
                <el-radio-button label="month">本月</el-radio-button>
              </el-radio-group>
            </div>
          </div>
          <div class="chart-wrapper">
            <div id="energyTrendChart" style="height: 320px;"></div>
          </div>
        </div>

        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="12">
            <div class="chart-section">
              <div class="section-title">能耗分布</div>
              <div id="energyDistChart" style="height: 280px;"></div>
            </div>
          </el-col>
          <el-col :span="12">
            <div class="chart-section">
              <div class="section-title">厂区能耗排行</div>
              <div id="factoryRankChart" style="height: 280px;"></div>
            </div>
          </el-col>
        </el-row>
      </el-col>

      <!-- 右侧：告警与收益 -->
      <el-col :span="10">
        <!-- 光伏收益 -->
        <div class="chart-section revenue-section">
          <div class="section-header">
            <div class="section-title">光伏收益分析</div>
            <div class="month-selector">
              <el-date-picker
                  v-model="pvMonth"
                  type="month"
                  placeholder="选择月份"
                  format="YYYY-MM"
                  value-format="YYYY-MM"
                  @change="fetchPVRevenue"
                  size="small"
              />
            </div>
          </div>
          <div class="revenue-content">
            <div class="revenue-metrics">
              <div class="revenue-metric">
                <div class="metric-label">发电总量</div>
                <div class="metric-value">{{ formatNumber(pvRevenue.total_generation) }} kWh</div>
              </div>
              <div class="revenue-metric">
                <div class="metric-label">自用电量</div>
                <div class="metric-value">{{ formatNumber(pvRevenue.self_use_kwh) }} kWh</div>
              </div>
              <div class="revenue-metric">
                <div class="metric-label">上网电量</div>
                <div class="metric-value">{{ formatNumber(pvRevenue.feed_in_kwh) }} kWh</div>
              </div>
              <div class="revenue-metric highlight">
                <div class="metric-label">总收益</div>
                <div class="metric-value">¥{{ formatNumber(pvRevenue.total_revenue) }}</div>
              </div>
            </div>
            <div class="revenue-detail">
              <div class="detail-item">
                <span class="label">自用节省：</span>
                <span class="value">¥{{ formatNumber(pvRevenue.self_use_saving) }}</span>
              </div>
              <div class="detail-item">
                <span class="label">上网收益：</span>
                <span class="value">¥{{ formatNumber(pvRevenue.feed_in_revenue) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 高等级告警推送 -->
        <div class="chart-section alert-section">
          <div class="section-header">
            <div class="section-title">高等级告警推送</div>
            <div class="alert-count">
              <span class="count-badge">{{ highAlerts.length }}</span>
              条未处理
            </div>
          </div>
          <div class="alert-list">
            <div
                v-for="(alert, index) in highAlerts"
                :key="alert.AlarmId"
                class="alert-item"
                :class="getAlertUrgency(alert)"
            >
              <div class="alert-header">
                <span class="alert-type">{{ alert.AlarmType }}</span>
                <span class="alert-level">{{ alert.AlarmLevel }}</span>
                <span class="alert-time">{{ formatTime(alert.OccurTime) }}</span>
              </div>
              <div class="alert-content">
                <div class="alert-device">
                  <span class="label">设备：</span>
                  <span class="value">{{ alert.DeviceName || alert.EquipmentType || '未知设备' }}</span>
                </div>
                <div class="alert-desc">{{ alert.Content }}</div>
                <div class="alert-stats">
                  <span class="unhandled-time">未处理：{{ alert.UnhandledMinutes }}分钟</span>
                  <span class="urgency" :class="getUrgencyClass(alert)">{{ alert.UrgencyLevel || '紧急' }}</span>
                </div>
              </div>
            </div>
            <div v-if="highAlerts.length === 0" class="no-alerts">
              🎉 当前无高等级告警
            </div>
          </div>
        </div>

        <!-- 告警统计 -->
        <div class="chart-section">
          <div class="section-title">告警统计分析</div>
          <div id="alertStatsChart" style="height: 180px;"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 能耗总结报告 -->
    <div class="report-section">
      <div class="section-header">
        <div class="section-title">能耗总结报告</div>
        <div class="report-controls">
          <el-radio-group v-model="reportPeriod" size="small" @change="fetchEnergyReport">
            <el-radio-button label="month">月度报告</el-radio-button>
            <el-radio-button label="quarter">季度报告</el-radio-button>
            <el-radio-button label="year">年度报告</el-radio-button>
          </el-radio-group>
          <el-date-picker
              v-model="reportDate"
              type="month"
              placeholder="选择报告期"
              format="YYYY-MM"
              value-format="YYYY-MM"
              @change="fetchEnergyReport"
              size="small"
              style="margin-left: 10px;"
          />
        </div>
      </div>

      <div class="report-content">
        <!-- 能耗对比 -->
        <div class="report-section-inner">
          <div class="subsection-title">能耗对比分析 ({{ reportData.period }})</div>
          <el-table :data="energyComparison" style="width: 100%" class="report-table">
            <el-table-column prop="type" label="能源类型" width="100" />
            <el-table-column prop="current" label="本期消耗" width="120">
              <template #default="scope">
                {{ formatNumber(scope.row.current) }} {{ getUnit(scope.row.type) }}
              </template>
            </el-table-column>
            <el-table-column prop="compare" label="同期对比" width="120">
              <template #default="scope">
                {{ formatNumber(scope.row.compare) }} {{ getUnit(scope.row.type) }}
              </template>
            </el-table-column>
            <el-table-column prop="change" label="变化率" width="100">
              <template #default="scope">
                <span :class="scope.row.change >= 0 ? 'negative' : 'positive'">
                  {{ scope.row.change >= 0 ? '+' : '' }}{{ scope.row.change.toFixed(1) }}%
                </span>
              </template>
            </el-table-column>
            <el-table-column prop="saving" label="节约量" width="120">
              <template #default="scope">
                <span v-if="scope.row.saving > 0" class="positive">
                  -{{ formatNumber(scope.row.saving) }} {{ getUnit(scope.row.type) }}
                </span>
                <span v-else-if="scope.row.saving < 0" class="negative">
                  +{{ formatNumber(Math.abs(scope.row.saving)) }} {{ getUnit(scope.row.type) }}
                </span>
                <span v-else>0</span>
              </template>
            </el-table-column>
            <el-table-column prop="completion" label="目标完成" width="120">
              <template #default="scope">
                <el-tag :type="scope.row.completed ? 'success' : 'danger'" size="small">
                  {{ scope.row.completed ? '达标' : '未达标' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <!-- 节能降耗目标 -->
        <div class="report-section-inner" style="margin-top: 20px;">
          <div class="subsection-title">降本增效目标完成情况</div>
          <div class="target-progress">
            <div class="target-item" v-for="item in targetProgress" :key="item.type">
              <div class="target-header">
                <span class="target-name">{{ item.type }}节约目标</span>
                <span class="target-rate">目标：{{ item.target }}%</span>
              </div>
              <div class="progress-bar">
                <div
                    class="progress-fill"
                    :class="item.completed ? 'success' : 'warning'"
                    :style="{ width: Math.min(Math.abs(item.actual), 100) + '%' }"
                >
                  <span class="progress-text">{{ item.actual.toFixed(1) }}%</span>
                </div>
              </div>
              <div class="target-footer">
                <span class="actual-rate">实际：{{ item.actual.toFixed(1) }}%</span>
                <span class="gap" :class="item.completed ? 'success' : 'danger'">
                  差距：{{ item.gap.toFixed(1) }}%
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 悬浮刷新按钮 -->
    <div class="floating-refresh" @click="refreshAll" title="刷新数据">
      🔄
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'
import { ElMessage } from 'element-plus'

// 响应式数据
const currentTime = ref('')
const timeRange = ref('today')
const pvMonth = ref('')
const reportPeriod = ref('month')
const reportDate = ref('')
const isFullScreen = ref(false)

// 核心指标数据
const coreMetrics = ref([
  { icon: '⚡', label: '今日总供电', value: 0, unit: 'kWh', trend: 'neutral', change: '0%' },
  { icon: '💧', label: '今日总供水', value: 0, unit: 'm³', trend: 'neutral', change: '0%' },
  { icon: '☀️', label: '光伏发电', value: 0, unit: 'kWh', trend: 'up', change: '+5.2%' },
  { icon: '🔋', label: '光伏自用', value: 0, unit: 'kWh', trend: 'up', change: '+8.1%' },
  { icon: '🚨', label: '活跃告警', value: 0, unit: '条', trend: 'down', change: '-12.3%' },
  { icon: '📊', label: '节能率', value: 0, unit: '%', trend: 'up', change: '+3.8%' }
])

// 光伏收益数据
const pvRevenue = ref({
  total_generation: 0,
  self_use_kwh: 0,
  feed_in_kwh: 0,
  self_use_saving: 0,
  feed_in_revenue: 0,
  total_revenue: 0
})

// 告警数据
const highAlerts = ref([])

// 报告数据
const reportData = ref({
  period: '',
  current_consumption: {},
  compare_consumption: {},
  saving_analysis: {},
  target_completion: {}
})

// 计算属性
const energyComparison = computed(() => {
  const types = ['电', '水', '蒸汽', '天然气']
  return types.map(type => {
    const current = reportData.value.current_consumption[type] || 0
    const compare = reportData.value.compare_consumption[type] || 0
    const analysis = reportData.value.saving_analysis[type] || {}
    const target = reportData.value.target_completion[type] || {}

    return {
      type,
      current,
      compare,
      change: analysis.change || 0,
      saving: compare > 0 ? compare - current : 0,
      completed: target.completed || false
    }
  })
})

const targetProgress = computed(() => {
  const types = ['电', '水', '蒸汽', '天然气']
  return types.map(type => {
    const target = reportData.value.target_completion[type] || {}
    return {
      type,
      target: target.target || 0,
      actual: target.actual || 0,
      completed: target.completed || false,
      gap: target.gap || 0
    }
  })
})

// ECharts 实例
let energyTrendChart = null
let energyDistChart = null
let factoryRankChart = null
let alertStatsChart = null

// 初始化时间
const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  })
}

// 格式化数字
const formatNumber = (num) => {
  if (num === undefined || num === null) return '0'
  if (num >= 1000000) return (num / 1000000).toFixed(2) + 'M'
  if (num >= 1000) return (num / 1000).toFixed(2) + 'K'
  return num.toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}

// 格式化时间
const formatTime = (timeStr) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  return date.toLocaleString('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 获取单位
const getUnit = (type) => {
  switch(type) {
    case '电': return 'kWh'
    case '水': return 'm³'
    case '蒸汽': return 'T'
    case '天然气': return 'm³'
    default: return ''
  }
}

// 获取告警紧急程度
const getAlertUrgency = (alert) => {
  const minutes = alert.UnhandledMinutes || 0
  if (minutes > 60) return 'urgent'
  if (minutes > 30) return 'important'
  return 'normal'
}

const getUrgencyClass = (alert) => {
  const minutes = alert.UnhandledMinutes || 0
  if (minutes > 60) return 'urgent'
  if (minutes > 30) return 'important'
  return 'normal'
}

// 切换全屏
const toggleFullScreen = () => {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen()
    isFullScreen.value = true
  } else {
    if (document.exitFullscreen) {
      document.exitFullscreen()
      isFullScreen.value = false
    }
  }
}

// API 请求函数
const fetchDashboardData = async () => {
  try {
    const response = await axios.get('http://localhost:8000/api/big_screen/data')
    const data = response.data

    // 更新核心指标
    coreMetrics.value[0].value = data.summary.daily_elec || 0
    coreMetrics.value[1].value = data.summary.daily_water || 0
    coreMetrics.value[2].value = data.summary.pv_gen || 0
    coreMetrics.value[3].value = data.summary.pv_self_use || 0
    coreMetrics.value[4].value = data.summary.active_alarms || 0

    // 计算节能率（简化计算）
    if (data.summary.daily_elec && data.summary.pv_self_use) {
      const savingRate = (data.summary.pv_self_use / data.summary.daily_elec * 100).toFixed(1)
      coreMetrics.value[5].value = parseFloat(savingRate)
    }

    // 更新图表数据
    initEnergyTrendChart(data.trend_data)
    initFactoryRankChart(data.rank_data)

    ElMessage.success('数据更新成功')
  } catch (error) {
    console.error('获取大屏数据失败:', error)
    ElMessage.error('数据更新失败')
  }
}

const fetchPVRevenue = async () => {
  try {
    const params = pvMonth.value ? { month: pvMonth.value } : {}
    const response = await axios.get('http://localhost:8000/api/big_screen/pv/revenue', { params })
    pvRevenue.value = response.data
  } catch (error) {
    console.error('获取光伏收益失败:', error)
  }
}

const fetchHighAlerts = async () => {
  try {
    const response = await axios.get('http://localhost:8000/api/big_screen/alerts/high-level', {
      params: { limit: 5 }
    })
    highAlerts.value = response.data.alerts || []
  } catch (error) {
    console.error('获取高等级告警失败:', error)
  }
}

const fetchEnergyReport = async () => {
  try {
    const params = {
      period: reportPeriod.value,
      year_month: reportDate.value
    }
    const response = await axios.get('http://localhost:8000/api/big_screen/energy/report', { params })
    reportData.value = response.data
    initAlertStatsChart(response.data)
  } catch (error) {
    console.error('获取能耗报告失败:', error)
  }
}

// 图表初始化函数
const initEnergyTrendChart = (data) => {
  if (!energyTrendChart) {
    energyTrendChart = echarts.init(document.getElementById('energyTrendChart'))
  }

  const hours = Array.from({ length: 24 }, (_, i) => `${i.toString().padStart(2, '0')}:00`)
  const values = Array(24).fill(0)

  data.forEach(item => {
    const hour = item.hour
    if (hour >= 0 && hour < 24) {
      values[hour] = item.value || 0
    }
  })

  const option = {
    tooltip: {
      trigger: 'axis',
      formatter: '{b}<br/>{a}: {c} kWh'
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: hours,
      axisLine: { lineStyle: { color: '#4a5a7a' } },
      axisLabel: { color: '#8c9bb8' }
    },
    yAxis: {
      type: 'value',
      name: 'kWh',
      axisLine: { lineStyle: { color: '#4a5a7a' } },
      axisLabel: { color: '#8c9bb8' },
      splitLine: { lineStyle: { color: '#2a3453', type: 'dashed' } }
    },
    series: [{
      name: '用电量',
      type: 'line',
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      lineStyle: {
        width: 3,
        color: '#1890ff'
      },
      itemStyle: {
        color: '#1890ff',
        borderColor: '#fff',
        borderWidth: 2
      },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(24, 144, 255, 0.5)' },
          { offset: 1, color: 'rgba(24, 144, 255, 0.1)' }
        ])
      },
      data: values
    }]
  }

  energyTrendChart.setOption(option)
}

const initEnergyDistChart = () => {
  if (!energyDistChart) {
    energyDistChart = echarts.init(document.getElementById('energyDistChart'))
  }

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{a}<br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      right: 10,
      top: 'center',
      textStyle: { color: '#8c9bb8' }
    },
    series: [{
      name: '能耗分布',
      type: 'pie',
      radius: ['40%', '70%'],
      center: ['35%', '50%'],
      avoidLabelOverlap: false,
      itemStyle: {
        borderRadius: 10,
        borderColor: '#0b0f20',
        borderWidth: 2
      },
      label: {
        show: true,
        formatter: '{b}\n{d}%'
      },
      emphasis: {
        label: {
          show: true,
          fontSize: '16',
          fontWeight: 'bold'
        }
      },
      data: [
        { value: 335, name: '生产用电' },
        { value: 310, name: '照明空调' },
        { value: 234, name: '设备动力' },
        { value: 135, name: '办公用电' },
        { value: 154, name: '其他' }
      ],
      color: ['#1890ff', '#13c2c2', '#52c41a', '#faad14', '#f5222d']
    }]
  }

  energyDistChart.setOption(option)
}

const initFactoryRankChart = (data) => {
  if (!factoryRankChart) {
    factoryRankChart = echarts.init(document.getElementById('factoryRankChart'))
  }

  const sortedData = [...data].sort((a, b) => b.value - a.value).slice(0, 8)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '5%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5a7a' } },
      axisLabel: { color: '#8c9bb8' },
      splitLine: { lineStyle: { color: '#2a3453' } }
    },
    yAxis: {
      type: 'category',
      data: sortedData.map(item => item.name),
      axisLine: { lineStyle: { color: '#4a5a7a' } },
      axisLabel: { color: '#8c9bb8' }
    },
    series: [{
      name: '能耗',
      type: 'bar',
      data: sortedData.map(item => item.value),
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#1890ff' },
          { offset: 1, color: '#36cbcb' }
        ]),
        borderRadius: [0, 5, 5, 0]
      },
      label: {
        show: true,
        position: 'right',
        color: '#8c9bb8'
      }
    }]
  }

  factoryRankChart.setOption(option)
}

const initAlertStatsChart = (reportData) => {
  if (!alertStatsChart) {
    alertStatsChart = echarts.init(document.getElementById('alertStatsChart'))
  }

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{a}<br/>{b}: {c} ({d}%)'
    },
    legend: {
      bottom: 0,
      left: 'center',
      textStyle: { color: '#8c9bb8' }
    },
    series: [{
      name: '告警统计',
      type: 'pie',
      radius: ['40%', '60%'],
      center: ['50%', '40%'],
      avoidLabelOverlap: false,
      label: {
        show: true,
        formatter: '{b}\n{d}%'
      },
      emphasis: {
        label: {
          show: true,
          fontSize: '14',
          fontWeight: 'bold'
        }
      },
      data: [
        { value: reportData.summary?.high_alarms || 0, name: '高等级告警' },
        { value: reportData.summary?.medium_alarm_count || 0, name: '中等级告警' },
        { value: reportData.summary?.low_alarm_count || 0, name: '低等级告警' }
      ],
      color: ['#f5222d', '#fa8c16', '#faad14']
    }]
  }

  alertStatsChart.setOption(option)
}

// 初始化能源趋势
const fetchEnergyTrend = () => {
  // 这里可以添加根据timeRange获取不同时间范围数据的逻辑
  console.log('获取能源趋势数据，时间范围:', timeRange.value)
}

// 刷新所有数据
const refreshAll = () => {
  fetchDashboardData()
  fetchPVRevenue()
  fetchHighAlerts()
  fetchEnergyReport()
  ElMessage.success('正在刷新所有数据...')
}

// 生命周期
onMounted(() => {
  // 初始化时间
  updateTime()
  setInterval(updateTime, 1000)

  // 设置默认月份
  const now = new Date()
  pvMonth.value = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}`
  reportDate.value = pvMonth.value

  // 初始化图表
  setTimeout(() => {
    energyTrendChart = echarts.init(document.getElementById('energyTrendChart'))
    energyDistChart = echarts.init(document.getElementById('energyDistChart'))
    factoryRankChart = echarts.init(document.getElementById('factoryRankChart'))
    alertStatsChart = echarts.init(document.getElementById('alertStatsChart'))

    // 获取数据
    refreshAll()

    // 初始化图表
    initEnergyDistChart()
  }, 100)

  // 监听窗口变化
  window.addEventListener('resize', () => {
    energyTrendChart?.resize()
    energyDistChart?.resize()
    factoryRankChart?.resize()
    alertStatsChart?.resize()
  })

  // 监听全屏变化
  document.addEventListener('fullscreenchange', () => {
    isFullScreen.value = !!document.fullscreenElement
  })

  // 自动刷新
  const refreshInterval = setInterval(refreshAll, 300000) // 每5分钟刷新一次

  onBeforeUnmount(() => {
    clearInterval(refreshInterval)
    window.removeEventListener('resize', () => {})
    document.removeEventListener('fullscreenchange', () => {})

    energyTrendChart?.dispose()
    energyDistChart?.dispose()
    factoryRankChart?.dispose()
    alertStatsChart?.dispose()
  })
})
</script>

<style scoped>
.screen-container {
  background-color: #0b0f20;
  min-height: 100vh;
  padding: 20px;
  color: #fff;
  font-family: 'Microsoft YaHei', sans-serif;
  position: relative;
}

/* 顶部标题栏 */
.screen-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #1e2952;
}

.header-left h1 {
  margin: 0;
  font-size: 28px;
  font-weight: bold;
  background: linear-gradient(135deg, #00f2ff, #409EFF);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.time-display {
  margin-top: 5px;
  color: #8c9bb8;
  font-size: 14px;
}

/* 核心指标区域 */
.metrics-section {
  margin-bottom: 25px;
}

.section-title {
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 15px;
  color: #fff;
  padding-left: 10px;
  border-left: 4px solid #409EFF;
}

.metrics-row {
  margin-bottom: 15px !important;
}

.metric-card {
  background: linear-gradient(135deg, rgba(24, 144, 255, 0.1), rgba(19, 194, 194, 0.1));
  border: 1px solid rgba(64, 158, 255, 0.3);
  border-radius: 8px;
  padding: 15px;
  display: flex;
  align-items: center;
  transition: all 0.3s ease;
  height: 100px;
}

.metric-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 20px rgba(64, 158, 255, 0.3);
}

.metric-card.up {
  border-color: rgba(82, 196, 26, 0.3);
}

.metric-card.down {
  border-color: rgba(245, 34, 45, 0.3);
}

.metric-icon {
  font-size: 32px;
  margin-right: 15px;
  width: 50px;
  text-align: center;
}

.metric-info {
  flex: 1;
}

.metric-value {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 5px;
  color: #00f2ff;
}

.metric-label {
  font-size: 12px;
  color: #8c9bb8;
  margin-bottom: 5px;
}

.metric-trend {
  font-size: 12px;
  padding: 2px 6px;
  border-radius: 3px;
  display: inline-block;
}

.metric-card.up .metric-trend {
  background: rgba(82, 196, 26, 0.2);
  color: #52c41a;
}

.metric-card.down .metric-trend {
  background: rgba(245, 34, 45, 0.2);
  color: #f5222d;
}

/* 图表区域 */
.chart-section {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid #1e2952;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.revenue-section {
  border-color: rgba(250, 173, 20, 0.3);
}

.revenue-content {
  padding: 10px 0;
}

.revenue-metrics {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
  margin-bottom: 15px;
}

.revenue-metric {
  background: rgba(255, 255, 255, 0.05);
  padding: 15px;
  border-radius: 6px;
  border: 1px solid rgba(64, 158, 255, 0.2);
}

.revenue-metric.highlight {
  background: rgba(250, 173, 20, 0.1);
  border-color: rgba(250, 173, 20, 0.3);
  grid-column: span 2;
}

.revenue-metric .metric-label {
  font-size: 12px;
  color: #8c9bb8;
  margin-bottom: 5px;
}

.revenue-metric .metric-value {
  font-size: 20px;
  font-weight: bold;
  color: #fff;
}

.revenue-metric.highlight .metric-value {
  color: #faad14;
  font-size: 24px;
}

.revenue-detail {
  background: rgba(255, 255, 255, 0.03);
  padding: 15px;
  border-radius: 6px;
  border: 1px solid rgba(64, 158, 255, 0.1);
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.detail-item:last-child {
  border-bottom: none;
}

.detail-item .label {
  color: #8c9bb8;
}

.detail-item .value {
  color: #fff;
  font-weight: bold;
}

/* 告警区域 */
.alert-section {
  border-color: rgba(245, 34, 45, 0.3);
}

.alert-count {
  display: flex;
  align-items: center;
  color: #f5222d;
  font-weight: bold;
}

.count-badge {
  background: rgba(245, 34, 45, 0.2);
  color: #f5222d;
  padding: 2px 8px;
  border-radius: 10px;
  margin-right: 5px;
}

.alert-list {
  max-height: 300px;
  overflow-y: auto;
}

.alert-item {
  background: rgba(255, 255, 255, 0.03);
  border-left: 4px solid;
  padding: 12px;
  margin-bottom: 10px;
  border-radius: 4px;
  transition: all 0.3s ease;
}

.alert-item:hover {
  background: rgba(255, 255, 255, 0.06);
}

.alert-item.urgent {
  border-left-color: #f5222d;
}

.alert-item.important {
  border-left-color: #fa8c16;
}

.alert-item.normal {
  border-left-color: #faad14;
}

.alert-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.alert-type {
  font-weight: bold;
  color: #fff;
}

.alert-level {
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 12px;
  font-weight: bold;
}

.alert-item.urgent .alert-level {
  background: rgba(245, 34, 45, 0.2);
  color: #f5222d;
}

.alert-item.important .alert-level {
  background: rgba(250, 140, 22, 0.2);
  color: #fa8c16;
}

.alert-item.normal .alert-level {
  background: rgba(250, 173, 20, 0.2);
  color: #faad14;
}

.alert-time {
  font-size: 12px;
  color: #8c9bb8;
}

.alert-content {
  font-size: 13px;
}

.alert-device {
  margin-bottom: 5px;
}

.alert-device .label {
  color: #8c9bb8;
}

.alert-device .value {
  color: #fff;
  font-weight: bold;
}

.alert-desc {
  margin-bottom: 8px;
  color: #d9d9d9;
  line-height: 1.4;
}

.alert-stats {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.unhandled-time {
  color: #fa8c16;
}

.urgency {
  padding: 2px 6px;
  border-radius: 3px;
  font-weight: bold;
}

.urgency.urgent {
  background: rgba(245, 34, 45, 0.2);
  color: #f5222d;
}

.urgency.important {
  background: rgba(250, 140, 22, 0.2);
  color: #fa8c16;
}

.urgency.normal {
  background: rgba(250, 173, 20, 0.2);
  color: #faad14;
}

.no-alerts {
  text-align: center;
  padding: 40px 20px;
  color: #8c9bb8;
  font-size: 16px;
}

/* 报告区域 */
.report-section {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid #1e2952;
  border-radius: 8px;
  padding: 20px;
  margin-top: 20px;
}

.report-content {
  margin-top: 20px;
}

.report-section-inner {
  background: rgba(255, 255, 255, 0.01);
  padding: 15px;
  border-radius: 6px;
  border: 1px solid rgba(64, 158, 255, 0.1);
}

.subsection-title {
  font-size: 16px;
  font-weight: bold;
  margin-bottom: 15px;
  color: #fff;
  padding-left: 8px;
  border-left: 3px solid #13c2c2;
}

.report-table {
  background: transparent !important;
}

/* 强制修改表格表头样式 */
:deep(.el-table th.el-table__cell) {
  background-color: #1a2235 !important; /* 修改为深色背景，对比度更强 */
  color: #00f2ff !important;            /* 表头文字改为亮青色，更醒目 */
  font-weight: bold;
  border-bottom: 2px solid #3b82f6 !important; /* 给表头下方加一条亮蓝色边框 */
  text-transform: uppercase;            /* 文字略微大写化，更有设计感 */
}

/* 修改表格行背景，确保整体深色风格统一 */
:deep(.el-table tr) {
  background-color: transparent !important;
  color: #ffffff;
}

/* 修改鼠标悬停时的行颜色，增强交互感 */
:deep(.el-table--enable-row-hover .el-table__row:hover > td.el-table__cell) {
  background-color: rgba(59, 130, 246, 0.2) !important;
}

.report-table .positive {
  color: #52c41a !important;
  font-weight: bold;
}

.report-table .negative {
  color: #f5222d !important;
  font-weight: bold;
}

.target-progress {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.target-item {
  background: rgba(255, 255, 255, 0.03);
  padding: 15px;
  border-radius: 6px;
  border: 1px solid rgba(64, 158, 255, 0.2);
}

.target-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.target-name {
  font-weight: bold;
  color: #fff;
}

.target-rate {
  color: #8c9bb8;
  font-size: 12px;
}

.progress-bar {
  height: 24px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  overflow: hidden;
  position: relative;
  margin: 10px 0;
}

.progress-fill {
  height: 100%;
  border-radius: 12px;
  transition: width 0.5s ease;
}

.progress-fill.success {
  background: linear-gradient(90deg, #52c41a, #a0d911);
}

.progress-fill.warning {
  background: linear-gradient(90deg, #faad14, #fa8c16);
}

.progress-text {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #fff;
  font-size: 12px;
  font-weight: bold;
}

.target-footer {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.actual-rate {
  color: #fff;
  font-weight: bold;
}

.gap.success {
  color: #52c41a;
}

.gap.danger {
  color: #f5222d;
}

/* 悬浮刷新按钮 */
.floating-refresh {
  position: fixed;
  bottom: 30px;
  right: 30px;
  width: 50px;
  height: 50px;
  background: rgba(64, 158, 255, 0.9);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
  transition: all 0.3s ease;
  z-index: 1000;
}

.floating-refresh:hover {
  transform: scale(1.1);
  background: rgba(64, 158, 255, 1);
  box-shadow: 0 6px 20px rgba(64, 158, 255, 0.4);
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb {
  background: rgba(64, 158, 255, 0.5);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(64, 158, 255, 0.7);
}

/* 响应式调整 */
@media (max-width: 1600px) {
  .metrics-row .el-col {
    width: 20% !important;
    max-width: 20% !important;
    flex: 0 0 20% !important;
  }

  .revenue-metrics {
    grid-template-columns: 1fr;
  }

  .revenue-metric.highlight {
    grid-column: span 1;
  }
}

@media (max-width: 1200px) {
  .main-content .el-col {
    width: 100% !important;
    max-width: 100% !important;
    flex: 0 0 100% !important;
  }

  .target-progress {
    grid-template-columns: 1fr;
  }
}
</style>