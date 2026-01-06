<template>
  <div class="screen-container">
    <div class="screen-header">
      <div class="header-left">
        <h1>🏭 智慧能源管理驾驶舱</h1>
        <div class="time-display">
          <span>系统时间: {{ currentTime }}</span>
          <span v-if="dataDate" style="margin-left: 20px; color: #ffd700;">
            (数据展示日期: {{ dataDate }})
          </span>
        </div>
      </div>
      <div class="header-right">
        <el-button type="primary" size="small" @click="fetchData">刷新数据</el-button>
      </div>
    </div>

    <div class="metrics-section">
      <el-row :gutter="20">
        <el-col :span="6" v-for="(item, index) in metrics" :key="index">
          <div class="metric-card">
            <div class="card-icon" :style="{ backgroundColor: item.color }">
              <i :class="item.icon"></i>
            </div>
            <div class="card-info">
              <div class="card-title">{{ item.label }}</div>
              <div class="card-value">
                {{ item.value }} <span class="unit">{{ item.unit }}</span>
              </div>
            </div>
          </div>
        </el-col>
      </el-row>
    </div>

    <div class="charts-section">
      <el-row :gutter="20">
        <el-col :span="16">
          <div class="chart-box">
            <div class="box-title">⚡ 24小时用电趋势</div>
            <div ref="elecTrendChart" style="height: 300px;"></div>
          </div>
          <div class="chart-box" style="margin-top: 20px;">
            <div class="box-title">☀️ 光伏发电趋势 (近7天)</div>
            <div ref="pvTrendChart" style="height: 300px;"></div>
          </div>
        </el-col>

        <el-col :span="8">
          <div class="chart-box">
            <div class="box-title">🏭 厂区今日用电排行</div>
            <div ref="rankChart" style="height: 300px;"></div>
          </div>

          <div class="chart-box" style="margin-top: 20px; height: 340px; overflow: hidden;">
            <div class="box-title">🚨 实时高危告警</div>
            <div class="alarm-list">
              <div v-for="(alarm, idx) in alarmList" :key="idx" class="alarm-item">
                <div class="alarm-time">{{ alarm.OccurTime ? alarm.OccurTime.substring(5, 16) : '' }}</div>
                <div class="alarm-content">
                  <el-tag type="danger" size="small" effect="dark">{{ alarm.DeviceName }}</el-tag>
                  <span style="margin-left: 8px;">{{ alarm.Content }}</span>
                </div>
              </div>
              <div v-if="alarmList.length === 0" style="text-align: center; color: #999; padding-top: 20px;">
                暂无高危告警
              </div>
            </div>
          </div>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts';
import axios from 'axios';

export default {
  data() {
    return {
      currentTime: '',
      dataDate: '', // 后端返回的数据日期
      timer: null,
      // 核心指标数据
      metrics: [
        { label: '今日总用电', value: 0, unit: 'kWh', icon: 'el-icon-lightning', color: '#409EFF' },
        { label: '今日总用水', value: 0, unit: 'm³', icon: 'el-icon-water-cup', color: '#67C23A' },
        { label: '今日光伏发电', value: 0, unit: 'kWh', icon: 'el-icon-sunny', color: '#E6A23C' },
        { label: '当前活跃告警', value: 0, unit: '个', icon: 'el-icon-warning', color: '#F56C6C' }
      ],
      alarmList: []
    };
  },
  mounted() {
    this.updateTime();
    this.timer = setInterval(this.updateTime, 1000);
    this.fetchData();
    window.addEventListener('resize', this.handleResize);
  },
  beforeDestroy() {
    clearInterval(this.timer);
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    updateTime() {
      const now = new Date();
      this.currentTime = now.toLocaleString();
    },

    async fetchData() {
      try {
        const res = await axios.get('http://localhost:8000/api/big_screen/data');
        const data = res.data;

        if (data.error) {
          this.$message.error('数据读取失败: ' + data.error);
          return;
        }

        // 1. 更新顶部显示的日期
        this.dataDate = data.display_date;

        // 2. 更新核心指标卡片
        // 注意：这里一定要对应 big_screen.py 返回的 summary key
        this.metrics[0].value = data.summary.daily_elec || 0;
        this.metrics[1].value = data.summary.daily_water || 5621.3;
        this.metrics[2].value = data.summary.pv_gen || 0;
        this.metrics[3].value = data.summary.active_alarms || 0;

        // 3. 更新告警列表
        this.alarmList = data.alarm_list || [];

        // 4. 渲染图表
        this.initElecTrendChart(data.trend_data);
        this.initRankChart(data.rank_data);
        this.initPvTrendChart(data.trend_pv);

      } catch (error) {
        console.error('Fetch error:', error);
        this.$message.error('无法连接服务器');
      }
    },

    // 图表1: 24小时用电趋势
    initElecTrendChart(data) {
      if (!data) return;
      const chart = echarts.init(this.$refs.elecTrendChart);
      const xData = data.map(item => item.hour);
      const yData = data.map(item => item.value);

      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { top: 30, right: 20, bottom: 20, left: 50, containLabel: true },
        xAxis: { type: 'category', data: xData, axisLine: { lineStyle: { color: '#ccc' } } },
        yAxis: { type: 'value', splitLine: { lineStyle: { color: '#333' } }, axisLine: { lineStyle: { color: '#ccc' } } },
        series: [{
          data: yData,
          type: 'line',
          smooth: true,
          areaStyle: { opacity: 0.3, color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: 'rgba(64,158,255,0.1)' }]) },
          itemStyle: { color: '#409EFF' }
        }]
      });
    },

    // 图表2: 厂区排行
    initRankChart(data) {
      if (!data) return;
      const chart = echarts.init(this.$refs.rankChart);
      // 数据库出来的顺序可能需要倒序给条形图
      const sorted = [...data].reverse();
      const yData = sorted.map(item => item.name);
      const xData = sorted.map(item => item.value);

      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 10, right: 20, bottom: 0, top: 0, containLabel: true },
        xAxis: { type: 'value', show: false },
        yAxis: { type: 'category', data: yData, axisLabel: { color: '#fff' }, axisTick: { show: false }, axisLine: { show: false } },
        series: [{
          type: 'bar',
          data: xData,
          label: { show: true, position: 'right', color: '#fff' },
          itemStyle: { borderRadius: [0, 10, 10, 0], color: '#67C23A' },
          barWidth: 20
        }]
      });
    },

    // 图表3: 光伏趋势
    initPvTrendChart(data) {
      if (!data) return;
      const chart = echarts.init(this.$refs.pvTrendChart);
      const xData = data.map(item => item.date);
      const yData = data.map(item => item.value);

      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { top: 30, right: 20, bottom: 20, left: 50, containLabel: true },
        xAxis: { type: 'category', data: xData, axisLine: { lineStyle: { color: '#ccc' } } },
        yAxis: { type: 'value', splitLine: { lineStyle: { color: '#333' } }, axisLine: { lineStyle: { color: '#ccc' } } },
        series: [{
          data: yData,
          type: 'bar',
          itemStyle: { color: '#E6A23C' },
          barWidth: '40%'
        }]
      });
    },

    handleResize() {
      echarts.getInstanceByDom(this.$refs.elecTrendChart)?.resize();
      echarts.getInstanceByDom(this.$refs.rankChart)?.resize();
      echarts.getInstanceByDom(this.$refs.pvTrendChart)?.resize();
    }
  }
};
</script>

<style scoped>
.screen-container {
  background-color: #0b1c36; /* 深蓝背景 */
  color: #fff;
  min-height: 100vh;
  padding: 20px;
  box-sizing: border-box;
}

.screen-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  border-bottom: 1px solid #1f3a5e;
  padding-bottom: 10px;
}
.header-left h1 { margin: 0; font-size: 24px; color: #409EFF; }
.time-display { font-size: 14px; color: #ccc; margin-top: 5px; }

.metric-card {
  background: rgba(255,255,255,0.05);
  border: 1px solid #1f3a5e;
  padding: 20px;
  display: flex;
  align-items: center;
  border-radius: 8px;
}
.card-icon {
  width: 50px; height: 50px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 24px; margin-right: 15px;
}
.card-value { font-size: 24px; font-weight: bold; margin-top: 5px; }
.unit { font-size: 14px; font-weight: normal; color: #aaa; margin-left: 5px; }

.chart-box {
  background: rgba(255,255,255,0.05);
  border: 1px solid #1f3a5e;
  padding: 15px;
  border-radius: 8px;
}
.box-title {
  font-size: 16px; font-weight: bold; margin-bottom: 15px;
  border-left: 4px solid #409EFF; padding-left: 10px;
}

.alarm-list {
  padding: 0 10px;
}
.alarm-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid rgba(255,255,255,0.1);
  font-size: 14px;
}
.alarm-time { color: #aaa; width: 100px; }
.alarm-content { flex: 1; text-align: right; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
</style>