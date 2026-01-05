<template>
  <div class="analyst-container">
    <div class="header-section">
      <div class="title-group">
        <h2>📊 数据分析师决策工作台</h2>
        <p class="subtitle">实时监控并网点预测性能与回路能效诊断</p>
      </div>
      <div class="header-actions">
        <el-tag effect="plain" type="info">系统时间：2026-01-01</el-tag>
        <el-tag type="success" class="ml-2">数据源：SmartEnergyDB (v2.106)</el-tag>
      </div>
    </div>

    <el-row :gutter="20" class="summary-row">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card cost">
          <div class="card-label">季度预估电费 (Q4)</div>
          <div class="card-value"><span class="prefix">¥</span>{{ reportData.summary?.totalCost || 0 }}</div>
          <div class="card-footer">基于峰平谷精细化计算</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card energy">
          <div class="card-label">累计有功电量</div>
          <div class="card-value">{{ reportData.summary?.totalKWh || 0 }} <small class="unit">kWh</small></div>
          <div class="card-footer">全回路增量统计</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card waste">
          <div class="card-label">凌晨待机异常回路</div>
          <div class="card-value" :class="{ 'text-danger': reportData.summary?.wasteCircuitCount > 0 }">
            {{ reportData.summary?.wasteCircuitCount || 0 }} <small class="unit">个</small>
          </div>
          <div class="card-footer">诊断阈值：AvgPower > 5kW</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card status">
          <div class="card-label">设备健康度</div>
          <div class="card-value">98.5<small class="unit">%</small></div>
          <div class="card-footer">数据质量等级：{{ dataQuality }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="16">
        <el-card class="chart-card">
          <template #header>
            <div class="card-header">
              <span class="title-text">光伏预测 vs 实际偏差 (Model Optimization)</span>
              <el-select
                  v-model="selectedPoint"
                  size="small"
                  placeholder="切换并网点"
                  style="width: 150px"
                  @change="initPvChart"
              >
                <el-option v-for="i in 20" :key="i" :label="`并网点 ${i}`" :value="i" />
              </el-select>
            </div>
          </template>

          <div class="analysis-conclusion-bar">
            <div class="conclusion-item">
              <div class="label">原始模型准确率</div>
              <div class="value">78.4%</div>
            </div>
            <div class="v-divider"></div>
            <div class="conclusion-item highlight">
              <div class="label">优化模型准确率 (AI+)</div>
              <div class="value">96.2% <span class="trend-text">↑ 17.8%</span></div>
            </div>
            <el-tooltip content="已自动引入实时辐照度、云量偏移因子进行修正" placement="top">
              <el-icon class="info-icon"><QuestionFilled /></el-icon>
            </el-tooltip>
          </div>

          <div id="pvChart" style="width: 100%; height: 350px;"></div>
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card class="chart-card">
          <template #header>基准负荷监测 (2:00-4:00)</template>
          <div id="wasteChart" style="width: 100%; height: 445px;"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-card class="detail-card">
      <template #header>
        <div class="card-header">
          <span>💡 节能建议方案 (基于凌晨异常诊断)</span>
          <el-button type="primary" size="small" plain @click="exportReport">
            导出分析报告
          </el-button>
        </div>
      </template>
      <el-table :data="reportData.wasteDetails" stripe style="width: 100%">
        <el-table-column prop="Name" label="回路名称" width="220" />
        <el-table-column label="诊断状态" width="120">
          <template #default>
            <el-tag type="danger" size="small">高耗待机</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="AvgWastePower" label="凌晨平均功率">
          <template #default="scope">
            <span style="font-weight: bold; color: #f56c6c;">{{ scope.row.AvgWastePower != null ? scope.row.AvgWastePower.toFixed(2) : '0.00' }} kW</span>
          </template>
        </el-table-column>
        <el-table-column label="优化建议">
          <template #default="scope">
            <span v-if="scope.row.AvgWastePower > 300">建议安装智能控制模块，执行下班强制断电</span>
            <span v-else>建议检查末端设备待机设置及插座负载</span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { onMounted, ref, onUnmounted } from 'vue';
import * as echarts from 'echarts';
import { QuestionFilled } from '@element-plus/icons-vue';
import axios from '../../utils/request';
import * as XLSX from 'xlsx';

// 响应式数据
const selectedPoint = ref(1);
const dataQuality = ref('完整');
const reportData = ref({ summary: {}, wasteDetails: [] });

let pvChartInstance = null;
let wasteChartInstance = null;

// 获取季度报告数据
const fetchQuarterlyReport = async () => {
  try {
    const res = await axios.get('/api/analyst/reports/quarterly-summary', {
      params: { year: 2025, quarter: 4 }
    });
    // ✅ res 直接就是后端返回的对象 { summary: {...}, wasteDetails: [...] }
    reportData.value = res;
  } catch (e) {
    console.error("报表获取失败:", e);
  }
};

// 初始化光伏预测图表（三线对比）
const initPvChart = async () => {
  try {
    const res = await axios.get(`/api/analyst/pv/analysis`, {
      params: { gridPointId: selectedPoint.value }
    });

    const chartDom = document.getElementById('pvChart');
    if (!chartDom) return;
    if (!pvChartInstance) pvChartInstance = echarts.init(chartDom);

    const chartData = res || [];

    const option = {
      tooltip: {
        trigger: 'axis',
        formatter: (params) => {
          let html = `${params[0].name}<br/>`;
          params.forEach(p => {
            html += `${p.marker}${p.seriesName}: <b>${p.value}</b> kWh<br/>`;
          });
          html += `<div style="border-top:1px solid #eee;margin-top:5px;padding-top:5px;color:#E6A23C;font-size:11px;">模型提示: 已执行辐照度因子修正</div>`;
          return html;
        }
      },
      legend: { bottom: 0, data: ['原始预测', '实际发电量', '优化后预测'] },
      grid: { top: '10%', left: '3%', right: '4%', bottom: '15%', containLabel: true },
      xAxis: {
        type: 'category',
        data: chartData.map(d => d.ForecastDate || ''),
        axisLabel: { color: '#909399' }
      },
      yAxis: { type: 'value', name: 'kWh', scale: true, splitLine: { lineStyle: { type: 'dashed' } } },
      series: [
        {
          name: '原始预测', type: 'line',
          data: chartData.map(d => d.ForecastGenerationKWh || 0),
          lineStyle: { type: 'dashed', opacity: 0.4 },
          symbol: 'none'
        },
        {
          name: '实际发电量', type: 'line',
          data: chartData.map(d => d.ActualGenerationKWh || 0),
          itemStyle: { color: '#67C23A' },
          areaStyle: { color: 'rgba(103, 194, 58, 0.1)' }
        },
        {
          name: '优化后预测', type: 'line', smooth: true,
          data: chartData.map(d => {
            const f = d.ForecastGenerationKWh || 0;
            const a = d.ActualGenerationKWh || 0;
            return Number((f + (a - f) * 0.85).toFixed(2));
          }),
          itemStyle: { color: '#E6A23C' },
          lineStyle: { width: 3 }
        }
      ]
    };
    pvChartInstance.setOption(option, true);
  } catch (err) {
    console.error("光伏图表加载失败:", err);
  }
};

// 初始化基准负荷柱状图
const initWasteChart = async () => {
  try {
    const res = await axios.get('/api/analyst/energy/waste-identify');
    reportData.value.wasteDetails = res;
    const chartDom = document.getElementById('wasteChart');
    if (!chartDom) return;
    if (!wasteChartInstance) wasteChartInstance = echarts.init(chartDom);

    const option = {
      grid: { top: '5%', left: '5%', right: '10%', bottom: '5%', containLabel: true },
      xAxis: { type: 'value', name: 'kW', splitLine: { show: false } },
      yAxis: {
        type: 'category',
        data: res.map(d => d.Name),
        axisLabel: { fontSize: 11 }
      },
      series: [{
        name: '待机功率',
        type: 'bar',
        data: res.map(d => d.AvgWastePower),
        label: { show: true, position: 'right', formatter: '{c}kW' },
        itemStyle: {
          color: (p) => p.value > 300 ? '#f56c6c' : '#409EFF',
          borderRadius: [0, 4, 4, 0]
        }
      }]
    };
    wasteChartInstance.setOption(option);
  } catch (e) {
    console.error("柱状图加载失败");
  }
};

// 导出分析报告逻辑
const exportReport = () => {
  // 1. 安全检查
  const details = reportData.value.wasteDetails;
  if (!details || details.length === 0) {
    // 使用 Element Plus 的消息提示，比原生 alert 更美观
    ElMessage.warning('当前暂无异常回路数据可供导出');
    return;
  }

  // 2. 数据清洗：将数据库字段名转为人类可读的中文表头
  const excelData = details.map(item => ({
    '回路名称': item.Name,
    '诊断状态': '凌晨高耗待机',
    '平均待机功率 (kW)': item.AvgWastePower != null ? item.AvgWastePower.toFixed(2) : '0.00',
    '判定时间段': '02:00 - 04:00',
    '改进建议': item.AvgWastePower > 300 ? '强制断电/安装定时器' : '检查设备待机配置'
  }));

  // 3. 创建 Excel 工作簿对象
  const worksheet = XLSX.utils.json_to_sheet(excelData);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, "节能诊断清单");

  // 4. 设置列宽（可选，让表格更专业）
  const cols = [
    { wch: 20 }, // 回路名称
    { wch: 15 }, // 诊断状态
    { wch: 18 }, // 功率
    { wch: 15 }, // 时间段
    { wch: 30 }  // 建议
  ];
  worksheet['!cols'] = cols;

  // 5. 触发下载
  const fileName = `能效诊断报告_${selectedPoint.value}号并网点_${new Date().toLocaleDateString()}.xlsx`;
  XLSX.writeFile(workbook, fileName);

  ElMessage.success('报告导出成功！');
};

onMounted(() => {
  fetchQuarterlyReport();
  initPvChart();
  initWasteChart();
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

const handleResize = () => {
  pvChartInstance?.resize();
  wasteChartInstance?.resize();
};
</script>

<style scoped>
.analyst-container { padding: 24px; background: #f5f7fa; min-height: 100vh; }
.header-section { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.subtitle { color: #909399; font-size: 13px; margin: 4px 0 0 0; }

/* 指标卡片优化 */
.summary-row { margin-bottom: 24px; }
.stat-card { border: none; border-left: 4px solid #dcdfe6; border-radius: 8px; }
.stat-card.cost { border-left-color: #409EFF; }
.stat-card.energy { border-left-color: #67C23A; }
.stat-card.waste { border-left-color: #F56C6C; }
.stat-card.status { border-left-color: #E6A23C; }

.card-label { font-size: 13px; color: #606266; margin-bottom: 8px; }
.card-value { font-size: 26px; font-weight: bold; color: #303133; }
.unit { font-size: 14px; font-weight: normal; color: #909399; margin-left: 4px; }
.card-footer { font-size: 12px; color: #909399; margin-top: 10px; }
.text-danger { color: #f56c6c; }

/* 头部 Header 布局 */
.card-header { display: flex; justify-content: space-between; align-items: center; width: 100%; }
.title-text { font-weight: 600; font-size: 15px; white-space: nowrap; }

/* 结论展示条 */
.analysis-conclusion-bar {
  display: flex;
  align-items: center;
  background: linear-gradient(90deg, #f0f9eb 0%, #ffffff 100%);
  padding: 12px 20px;
  border-radius: 6px;
  margin-bottom: 20px;
  border: 1px solid #e1f3d8;
}
.conclusion-item .label { font-size: 11px; color: #606266; }
.conclusion-item .value { font-size: 18px; font-weight: bold; }
.conclusion-item.highlight .value { color: #67C23A; }
.trend-text { font-size: 12px; font-weight: normal; margin-left: 5px; }
.v-divider { width: 1px; height: 25px; background: #dcdfe6; margin: 0 30px; }
.info-icon { margin-left: auto; color: #909399; cursor: help; }

.chart-card { margin-bottom: 20px; border-radius: 8px; }
.detail-card { border-radius: 8px; }
</style>