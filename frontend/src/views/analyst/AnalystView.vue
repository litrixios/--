<template>
  <div class="analyst-container">
    <h2>📊 数据分析师工作台</h2>

    <el-card class="filter-card">
      <el-form :inline="true">
        <el-form-item label="并网点选择">
          <el-select v-model="selectedPoint" placeholder="请选择并网点" @change="handleRefresh">
            <el-option v-for="i in 20" :key="i" :label="`PV-GP-0${i < 10 ? '0'+i : i}`" :value="i" />
          </el-select>
        </el-form-item>
        <el-tag type="info">对齐数据版本：v2.2 / v2.106</el-tag>
      </el-form>
    </el-card>

    <div class="chart-card">
      <h3>光伏发电预测 vs 实际 (偏差分析)</h3>
      <div id="pvChart" style="width: 100%; height: 400px;"></div>
    </div>

    <div class="chart-card">
      <h3>回路基准负荷监测 (寻找节能潜力)</h3>
      <div id="wasteChart" style="width: 100%; height: 300px;"></div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import * as echarts from 'echarts';
import axios from 'axios';

const selectedPoint = ref(1); // 默认看 1 号并网点
let pvChartInstance = null;
let wasteChartInstance = null;

const initPvChart = async () => {
  // 接口增加参数，对齐后端查询逻辑
  const res = await axios.get(`/api/analyst/pv/analysis?gridPointId=${selectedPoint.value}`);

  // 处理数据：由于 SQL 生成了多个 TimeRange，前端需要按日期聚合或选择特定展示方式
  // 这里我们按日期取平均值或总和展示
  const chartDom = document.getElementById('pvChart');
  if (!pvChartInstance) pvChartInstance = echarts.init(chartDom);

  const option = {
    tooltip: { trigger: 'axis' },
    legend: { data: ['预测发电量', '实际发电量'] },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      data: res.data.map(d => d.ForecastDate),
      inverse: false // 确保日期从左往右
    },
    yAxis: { type: 'value', name: 'kWh' },
    series: [
      {
        name: '预测发电量',
        type: 'line',
        smooth: true,
        data: res.data.map(d => d.ForecastGenerationKWh), // 字段名对齐 SQL
        lineStyle: { type: 'dashed', color: '#409EFF' }
      },
      {
        name: '实际发电量',
        type: 'line',
        smooth: true,
        data: res.data.map(d => d.ActualGenerationKWh), // 字段名对齐 SQL
        areaStyle: { opacity: 0.1 },
        itemStyle: { color: '#67C23A' },
        // 增加标记点，突出显示大偏差（对齐 SQL 中的 ForceBigDeviation 逻辑）
        markPoint: {
          data: [
            { type: 'max', name: '峰值' },
            { name: '异常偏差', coord: ['2025-12-30', 32924], value: '!', itemStyle: {color: '#F56C6C'} }
          ]
        }
      }
    ]
  };
  pvChartInstance.setOption(option);
};

const handleRefresh = () => {
  initPvChart();
};

const initWasteChart = async () => {
  try {
    const res = await axios.get('/api/analyst/energy/waste-identify');
    const chartDom = document.getElementById('wasteChart');
    if (!wasteChartInstance) wasteChartInstance = echarts.init(chartDom);

    const option = {
      title: { text: '凌晨2-4点基准负荷 (KW)', textStyle: { fontSize: 14 } },
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'value' },
      yAxis: { type: 'category', data: res.data.map(d => d.CircuitName || '未命名回路') },
      series: [{
        type: 'bar',
        data: res.data.map(d => d.MidnightAvgPower),
        itemStyle: {
          color: (params) => params.value > 10 ? '#f56c6c' : '#1890ff'
        },
        label: { show: true, position: 'right' }
      }]
    };
    wasteChartInstance.setOption(option);
  } catch (e) {
    console.log("基准负荷数据为空，请检查数据库插入脚本");
  }
};

onMounted(() => {
  initPvChart();
  initWasteChart();

  // 响应式处理
  window.addEventListener('resize', () => {
    pvChartInstance?.resize();
    wasteChartInstance?.resize();
  });
});
</script>

<style scoped>
.analyst-container { padding: 20px; background: #f5f7fa; min-height: 100vh; }
.filter-card { margin-bottom: 20px; }
.chart-card { background: #fff; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 12px rgba(0,0,0,0.1); }
</style>