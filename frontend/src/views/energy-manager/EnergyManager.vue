<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'
import * as echarts from 'echarts'

// --- 1. 基础配置 ---
const activeTab = ref('report')
const request = axios.create({
  baseURL: 'http://localhost:8000/api/energy_manager',
  timeout: 5000
})

const reportList = ref([])
const auditList = ref([])
const loadingReport = ref(false)
const loadingAudit = ref(false)

// 修改：动态获取的厂区列表
const areaOptions = ref([])  // 动态厂区选项
const searchArea = ref('')   // 选中的厂区
const searchEnergyType = ref('')

const dialogVisible = ref(false)
const newPlan = ref({title: '', target: '', content: ''})
let myChart = null
let pieChart = null

// --- 1.1 新增分析相关变量 ---
const analysisMonth = ref('2025-11')
const analysisData = ref({ current_total: 0, mom: 0, yoy: 0, trend: [] })
let anaChart = null

// --- 1.2 添加初始化函数，获取动态数据 ---
const fetchDynamicData = async () => {
  try {
    // 1. 获取厂区列表
    const areaRes = await request.get('/area/list')
    areaOptions.value = areaRes.data.map(item => ({
      label: item.AreaName,
      value: item.AreaName
    }))

    console.log('加载的厂区列表:', areaOptions.value)

    // 2. 如果有数据，默认选择第一个厂区
    if (areaOptions.value.length > 0 && !searchArea.value) {
      searchArea.value = areaOptions.value[0].value
    }

  } catch (err) {
    console.error('加载动态数据失败:', err)
    // 如果接口失败，使用备用数据
    areaOptions.value = [
      { label: '城南工业园主厂区', value: '城南工业园主厂区' },
      { label: '城北新能源分厂', value: '城北新能源分厂' },
      { label: '东郊光伏产业园', value: '东郊光伏产业园' }
    ]
  }
}

// --- 2. 业务逻辑计算 ---

// 2.1 精准划分峰谷时段 (根据业务文档)
const getTOUType = (timeStr) => {
  const hour = new Date(timeStr).getHours()
  // 尖峰：10:00-12:00 / 16:00-18:00
  if ((hour >= 10 && hour < 12) || (hour >= 16 && hour < 18)) return '尖峰'
  // 高峰：8:00-10:00 / 12:00-16:00 / 18:00-22:00
  if ((hour >= 8 && hour < 10) || (hour >= 12 && hour < 16) || (hour >= 18 && hour < 22)) return '高峰'
  // 低谷：00:00-06:00
  if (hour >= 0 && hour < 6) return '低谷'
  // 平段：06:00-08:00 / 22:00-24:00
  return '平段'
}

const getTOUColor = (type) => {
  const map = {'尖峰': '#cf1322', '高峰': '#fa8c16', '平段': '#409EFF', '低谷': '#52c41a'}
  return map[type] || '#909399'
}

const getUnit = (type) => {
  const map = {'电': 'kWh', '水': 'm³', '天然气': 'm³', '蒸汽': 't'}
  return map[type] || ''
}

// 2.2 数据预处理 (核心业务实现：成本计算 + 30%异常标记)
const processedReportList = computed(() => {
  if (reportList.value.length === 0) return []

  // 计算全场均值
  const avgVal = reportList.value.reduce((s, c) => s + c.Value, 0) / reportList.value.length

  return reportList.value.map(item => {
    const touType = getTOUType(item.CollectTime)
    // 模拟阶梯电价：尖1.5, 高1.1, 平0.7, 低0.3
    const priceMap = {'尖峰': 1.5, '高峰': 1.1, '平段': 0.7, '低谷': 0.3}
    const cost = (item.Value * (priceMap[touType] || 0.7)).toFixed(2)

    // 异常判定逻辑：超均值30% 或 质量为中/差
    const isOverLimit = item.Value > (avgVal * 1.3)
    const isQualityPoor = ['中', '差'].includes(item.Quality)

    return {
      ...item,
      touType,
      estimatedCost: cost,
      isAnomaly: isOverLimit || isQualityPoor,
      anomalyReason: isOverLimit ? '能耗超过全厂均值30%' : (isQualityPoor ? '采集质量差需核实' : '')
    }
  })
})

const totalCost = computed(() => {
  return processedReportList.value.reduce((s, c) => s + parseFloat(c.estimatedCost), 0).toFixed(2)
})

// --- 3. API & 图表 ---

const fetchReport = async () => {
  loadingReport.value = true
  try {
    const res = await request.get('/report', {
      params: {area_name: searchArea.value, energy_type: searchEnergyType.value}
    })
    reportList.value = res.data
    updateChart(res.data)
  } catch (err) {
    ElMessage.error('报表获取失败，请检查后端端口8000及跨域设置')
  } finally {
    loadingReport.value = false
  }
}

const updateChart = (data) => {
  // 1. 检查图表实例是否存在，防止报错
  if (!myChart || !pieChart) return

  // 2. 处理 X 轴数据：显示 年-月-日 并换行显示 时间
  const xData = data.map(item => {
    const date = new Date(item.CollectTime);
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    const time = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // 返回格式：2026-01-02 (换行) 14:30
    return `${y}-${m}-${d}\n${time}`;
  });

  // 3. 配置折线趋势图
  myChart.setOption({
    title: { text: '实时能耗趋势' },
    tooltip: {
      trigger: 'axis',
      formatter: (params) => {
        // 在提示框里把换行符替换为空格，显示更美观
        let res = params[0].name.replace('\n', ' ') + '<br/>';
        params.forEach(item => {
          res += `${item.marker} ${item.seriesName}: <b>${item.value}</b>`;
        });
        return res;
      }
    },
    grid: {
      bottom: '15%', // 留出空间给两行显示的日期
      left: '5%',
      right: '5%'
    },
    dataZoom: [
      { type: 'slider', start: 0, end: 100, bottom: '2%' },
      { type: 'inside' }
    ],
    xAxis: {
      type: 'category',
      data: xData,
      axisLabel: {
        interval: 'auto',
        lineHeight: 15,
        fontSize: 11
      }
    },
    yAxis: { type: 'value', name: '数值' },
    series: [{
      name: '能耗值',
      data: data.map(i => i.Value),
      type: 'line',
      smooth: true,
      areaStyle: { opacity: 0.2 },
      itemStyle: { color: '#409EFF' }
    }]
  })

  // 4. 配置饼图 (峰谷占比)
  const stats = {}
  data.forEach(i => {
    const t = getTOUType(i.CollectTime)
    stats[t] = (stats[t] || 0) + i.Value
  })

  pieChart.setOption({
    title: { text: '峰谷能耗构成', left: 'center' },
    tooltip: { trigger: 'item' },
    series: [{
      name: '能耗占比',
      type: 'pie',
      radius: ['40%', '70%'],
      avoidLabelOverlap: true,
      label: { show: true, formatter: '{b}\n{d}%' },
      data: Object.keys(stats).map(k => ({
        name: k,
        value: stats[k],
        itemStyle: { color: getTOUColor(k) }
      }))
    }]
  })
}

const fetchAudit = async () => {
  loadingAudit.value = true
  try {
    const res = await request.get('/audit/pending')
    auditList.value = res.data
  } finally {
    loadingAudit.value = false
  }
}

const handleVerify = async (row, isValid) => {
  await request.post('/audit/verify', {data_id: row.DataId, is_valid: isValid})
  ElMessage.success('核查完成')
  fetchAudit()
}

// --- 3.1 修改分析相关方法：使用真实后端数据 ---
const fetchAnalysis = async () => {
  try {
    // 调用真实的后端接口
    const res = await request.get('/analysis', {
      params: {
        month: analysisMonth.value,
        area_name: searchArea.value || null,
        energy_type: '电' // 根据后端接口，这里默认用电数据
      }
    })

    // 使用后端返回的真实数据
    analysisData.value = res.data

    // 初始化或更新图表
    nextTick(() => {
      if (!anaChart) {
        anaChart = echarts.init(document.getElementById('analysisChart'))
      }

      // 处理日期格式，只显示月-日
      const formattedDates = res.data.trend.map(item => {
        const date = new Date(item.date)
        return `${date.getMonth() + 1}-${date.getDate()}`
      })

      anaChart.setOption({
        title: {
          text: `${analysisMonth.value} 每日能耗趋势`,
          left: 'center'
        },
        tooltip: {
          trigger: 'axis',
          formatter: (params) => {
            const date = res.data.trend[params[0].dataIndex].date
            return `${date}<br/>能耗: ${params[0].value} kWh`
          }
        },
        xAxis: {
          type: 'category',
          data: formattedDates,
          axisLabel: {
            interval: 0,
            fontSize: 10
          }
        },
        yAxis: {
          type: 'value',
          name: '能耗 (kWh)'
        },
        series: [{
          name: '能耗量',
          type: 'line',
          smooth: true,
          data: res.data.trend.map(i => i.value),
          itemStyle: { color: '#67C23A' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(103, 194, 58, 0.3)' },
              { offset: 1, color: 'rgba(103, 194, 58, 0.1)' }
            ])
          }
        }]
      })
    })
  } catch (err) {
    console.error('获取分析报告失败:', err)
    ElMessage.error('获取分析报告失败，请检查数据库连接')

    // 如果后端接口失败，显示空数据
    analysisData.value = {
      current_total: 0,
      mom: 0,
      yoy: 0,
      trend: []
    }
  }
}

// --- 4. 生命周期与辅助 ---
const plans = ref([{
  date: '2025-11-20',
  title: '空压机系统优化',
  content: '修复泄漏点，预计能耗下降5%',
  status: '进行中',
  target: '5%',
  type: 'primary'
}])

const addPlan = () => {
  plans.value.unshift({
    ...newPlan.value,
    date: new Date().toISOString().split('T')[0],
    status: '已计划',
    type: 'warning'
  })
  dialogVisible.value = false
  ElMessage.success('方案已加入跟踪')
}

const formatDate = (v) => v ? new Date(v).toLocaleString() : '-'

// --- 5. 统一的标签页点击处理函数 ---
const handleTabClick = (tab) => {
  const tabName = tab.props.name

  if (tabName === 'report') {
    nextTick(() => {
      myChart?.resize()
      pieChart?.resize()
    })
    fetchReport()
  } else if (tabName === 'audit') {
    fetchAudit()
  } else if (tabName === 'analysis') {
    fetchAnalysis()
    nextTick(() => {
      anaChart?.resize()
    })
  }
}

onMounted(async () => {
  // 初始化时加载动态数据
  await fetchDynamicData()

  // 初始化图表
  myChart = echarts.init(document.getElementById('energyChart'))
  pieChart = echarts.init(document.getElementById('pieChart'))

  // 初始化分析图表
  anaChart = echarts.init(document.getElementById('analysisChart'))

  // 初始加载数据
  fetchReport()

  // 窗口大小变化时调整图表
  window.addEventListener('resize', () => {
    myChart?.resize()
    pieChart?.resize()
    anaChart?.resize()
  })
})
</script>

<template>
  <div class="energy-container">
    <div class="header">
      <div class="title-section">
        <h2>⚡ 能源管理中心</h2>
        <p class="subtitle">负责全厂能耗监控、数据核查及节能优化方案制定。</p>
      </div>
      <div class="status-panel">
        <el-statistic title="今日预估总成本" :value="totalCost" prefix="￥" group-separator="," />
        <el-statistic title="待核实异常" :value="auditList.length" suffix="项" value-style="color: #cf1322" />
      </div>
    </div>

    <el-tabs v-model="activeTab" type="border-card" @tab-click="handleTabClick">
      <el-tab-pane label="📊 能耗报表 & 峰谷分析" name="report">
        <div class="filter-bar">
          <!-- 修改：使用动态厂区选项 -->
          <el-select v-model="searchArea" placeholder="选择厂区" clearable filterable style="width: 250px">
            <el-option
                v-for="area in areaOptions"
                :key="area.value"
                :label="area.label"
                :value="area.value"
            />
          </el-select>

          <el-select v-model="searchEnergyType" placeholder="能源类型" clearable style="width: 150px; margin-left: 10px;">
            <el-option label="电" value="电" />
            <el-option label="水" value="水" />
            <el-option label="天然气" value="天然气" />
            <el-option label="蒸汽" value="蒸汽" />
          </el-select>

          <el-button type="primary" @click="fetchReport" icon="Search" style="margin-left: 10px;">执行查询</el-button>
        </div>

        <el-row :gutter="20" justify="center" style="background: #fff; padding: 20px 0; border-radius: 8px;">
          <el-col :span="16">
            <div id="energyChart" style="width: 100%; height: 400px;"></div>
          </el-col>
          <el-col :span="7">
            <div id="pieChart" style="width: 100%; height: 400px;"></div>
          </el-col>
        </el-row>

        <el-divider content-position="left">详细数据报表 (含峰谷成本核算)</el-divider>

        <el-table :data="processedReportList" style="width: 100%" height="400" stripe border v-loading="loadingReport">
          <el-table-column prop="CollectTime" label="采集时间" width="160">
            <template #default="scope">{{ formatDate(scope.row.CollectTime) }}</template>
          </el-table-column>
          <el-table-column prop="AreaName" label="厂区" width="120" />
          <el-table-column label="峰谷时段" width="100">
            <template #default="scope">
              <el-tag :color="getTOUColor(scope.row.touType)" effect="dark" size="small" style="border:none">
                {{ scope.row.touType }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="EnergyType" label="能源" width="80" />
          <el-table-column label="能耗值" width="120">
            <template #default="scope">
              <span style="font-weight: bold; color: #409EFF">{{ scope.row.Value }} {{ getUnit(scope.row.EnergyType) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="估算成本" width="110">
            <template #default="scope">
              <span style="font-weight: bold; color: #67C23A">￥{{ scope.row.estimatedCost }}</span>
            </template>
          </el-table-column>
          <el-table-column label="数据质量" width="100">
            <template #default="scope">
              <el-tag :type="scope.row.Quality === '优' ? 'success' : 'warning'">{{ scope.row.Quality || '优' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="预警状态">
            <template #default="scope">
              <el-tooltip v-if="scope.row.isAnomaly" :content="scope.row.anomalyReason" placement="top">
                <el-tag type="danger" icon="WarningFilled">异常预警</el-tag>
              </el-tooltip>
              <el-tag v-else type="success">采集正常</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="🔍 异常数据核查" name="audit">
        <el-alert title="数据质量为'中/差'或波动超30%的记录已自动标记，请人工核查。" type="warning" show-icon :closable="false" style="margin-bottom: 20px;" />
        <el-table :data="auditList" style="width: 100%" v-loading="loadingAudit" border>
          <el-table-column prop="CollectTime" label="时间" width="180">
            <template #default="scope">{{ formatDate(scope.row.CollectTime) }}</template>
          </el-table-column>
          <el-table-column prop="AreaName" label="厂区" width="120" />
          <el-table-column prop="Value" label="异常读数" width="120">
            <template #default="scope"><span style="color: red; font-weight: bold;">{{ scope.row.Value }}</span></template>
          </el-table-column>
          <el-table-column prop="Quality" label="质量标记" width="100" />
          <el-table-column label="操作">
            <template #default="scope">
              <el-button type="success" size="small" @click="handleVerify(scope.row, true)">通过 (有效)</el-button>
              <el-button type="danger" size="small" @click="handleVerify(scope.row, false)">驳回 (故障)</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="🌱 节能优化方案" name="plan">
        <div class="plan-header">
          <span>方案实施跟踪：监控优化后的能耗下降曲线。</span>
          <el-button type="primary" @click="dialogVisible = true">+ 新增节能方案</el-button>
        </div>
        <el-timeline style="margin-top: 20px;">
          <el-timeline-item v-for="(activity, index) in plans" :key="index" :timestamp="activity.date" :type="activity.type">
            <el-card>
              <h4>{{ activity.title }}</h4>
              <p>{{ activity.content }}</p>
              <div class="plan-tags">
                <el-tag size="small">{{ activity.status }}</el-tag>
                <el-tag size="small" type="success" style="margin-left: 10px;">目标: {{ activity.target }}</el-tag>
              </div>
            </el-card>
          </el-timeline-item>
        </el-timeline>
      </el-tab-pane>

      <el-tab-pane label="📈 历史趋势分析报告" name="analysis">
        <div class="filter-bar">
          <el-date-picker v-model="analysisMonth" type="month" value-format="YYYY-MM" placeholder="选择月份" @change="fetchAnalysis" />
          <!-- 修改：使用动态厂区选项 -->
          <el-select v-model="searchArea" placeholder="选择厂区" @change="fetchAnalysis" clearable filterable style="margin-left:10px; width:250px">
            <el-option label="全厂汇总" value="" />
            <el-option
                v-for="area in areaOptions"
                :key="area.value"
                :label="area.label"
                :value="area.value"
            />
          </el-select>
          <el-button type="success" @click="fetchAnalysis" icon="TrendCharts" style="margin-left:10px">生成分析报告</el-button>
        </div>

        <el-row :gutter="20">
          <el-col :span="8">
            <el-card shadow="hover" class="ana-card">
              <template #header>本月总能耗</template>
              <div class="ana-num">{{ analysisData.current_total }} <span class="unit">kWh</span></div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card shadow="hover" class="ana-card">
              <template #header>环比增长 (MoM)</template>
              <div :class="['ana-num', analysisData.mom > 0 ? 'text-danger' : 'text-success']">
                {{ analysisData.mom > 0 ? '+' : '' }}{{ analysisData.mom }}%
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card shadow="hover" class="ana-card">
              <template #header>同比增长 (YoY)</template>
              <div :class="['ana-num', analysisData.yoy > 0 ? 'text-danger' : 'text-success']">
                {{ analysisData.yoy > 0 ? '+' : '' }}{{ analysisData.yoy }}%
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-card style="margin-top: 20px;">
          <div id="analysisChart" style="height: 400px; width: 100%;"></div>
        </el-card>

        <el-card style="margin-top: 20px;" class="conclusion">
          <h4>💡 节能效果评估</h4>
          <p v-if="analysisData.mom < 0">
            本月能耗环比下降 <b>{{ Math.abs(analysisData.mom) }}%</b>。评估：节能措施效果<b>显著</b>，建议维持当前策略。
          </p>
          <p v-else>
            本月能耗环比有所上升，需核查是否存在生产高峰或设备空转现象。
          </p>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="dialogVisible" title="制定优化方案" width="35%">
      <el-form label-width="100px">
        <el-form-item label="方案名称"><el-input v-model="newPlan.title" placeholder="如：调整熔炼工序至谷电时段" /></el-form-item>
        <el-form-item label="预期目标"><el-input v-model="newPlan.target" placeholder="如：电费下降15%" /></el-form-item>
        <el-form-item label="详细内容"><el-input v-model="newPlan.content" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="addPlan">确认实施</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.energy-container {
  padding: 20px;
  background-color: #f5f7fa;
  min-height: 100vh;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

.subtitle {
  color: #909399;
  font-size: 14px;
  margin-top: 5px;
}

.status-panel {
  display: flex;
  gap: 50px;
}

.filter-bar {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  padding: 15px;
  background: #fff;
  border-radius: 4px;
}

.plan-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.ana-card { text-align: center; }
.ana-num { font-size: 28px; font-weight: bold; margin: 10px 0; }
.text-danger { color: #F56C6C; }
.text-success { color: #67C23A; }
.unit { font-size: 14px; color: #999; }
.conclusion { border-left: 6px solid #67C23A; background-color: #f0f9eb; }
</style>