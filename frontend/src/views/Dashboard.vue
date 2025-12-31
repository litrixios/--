<template>
  <div class="dashboard-container">

    <div class="header-section">
      <h1>⚡ 智慧能源管理系统 <small style="font-size: 14px; color: #999; font-weight: normal;">(v1.0 究极肝帝版)</small></h1>
    </div>

    <el-row :gutter="20">

      <el-col :span="14">
        <el-card class="meme-card" shadow="hover">
          <div class="meme-content">
            <div class="typing-effect">
              💪 小牛马，今天也要认真上班哦！
            </div>

            <div class="image-wrapper">
              <img src="../assets/cow.jpg" alt="working hard" class="cow-img" />
              <div class="image-caption">👆 图：现在的你 (监控画面实时回传)</div>
            </div>

            <div class="fake-stats">
              <div class="stat-item">
                <span>距离退休进度：</span>
                <el-progress :percentage="0.01" status="exception" :format="() => '0.01% (遥遥无期)'" />
              </div>
              <div class="stat-item">
                <span>今日精神状态：</span>
                <el-progress :percentage="5" color="#f56c6c" :format="() => '5% (快崩溃了)'" />
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="10">
        <el-card class="role-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <span>🆔 身份识别卡</span>
              <el-tag type="success" effect="dark">在岗</el-tag>
            </div>
          </template>

          <div class="user-info">
            <div class="avatar-placeholder">{{ role[0] }}</div>
            <div class="info-text">
              <h3>{{ userRealName || '无名氏' }}</h3>
              <p>工号：9527</p>
              <p>岗位：<el-tag>{{ role }}</el-tag></p>
            </div>
          </div>

          <el-divider content-position="center">今日搬砖指引</el-divider>

          <div class="action-tips">

            <div v-if="role === '运维工单管理员' || role === 'WorkOrderAdmin'" class="tip-box admin-tip">
              <h4>🚨 调度指令</h4>
              <p>有一堆告警等着你去派单呢！别偷懒！</p>
              <el-button type="primary" @click="$router.push('/dispatch-center')">
                前往调度中心 (去受苦)
              </el-button>
            </div>

            <div v-if="role === '运维人员' || role === 'Maintainer' || role.includes('运维')" class="tip-box worker-tip">
              <h4>🔧 维修指令</h4>
              <p>设备又坏了，背上工具包出发吧！</p>
              <el-button type="warning" @click="$router.push('/my-tasks')">
                查看维修任务 (去跑腿)
              </el-button>
            </div>

            <div v-if="role === 'Admin'" class="tip-box system-tip">
              <h4>🛠️ 最高权限指令</h4>
              <p>数据库还没备份，账号还没审核，<br>你竟然在这看小牛马？</p>
              <el-button type="danger" @click="$router.push('/system-admin')">
                进入管理后台 (去坐牢)
              </el-button>
            </div>

            <div v-if="!['运维工单管理员', 'WorkOrderAdmin', '运维人员', 'Maintainer'].includes(role) && !role.includes('运维')" class="tip-box">
              <p>你好像没有分配具体的搬砖任务，<br>建议摸鱼。</p>
            </div>

          </div>
        </el-card>

        <el-card style="margin-top: 20px;" shadow="hover">
          <h3>☕ 摸鱼小贴士</h3>
          <p style="font-size: 12px; color: #666; line-height: 1.6;">
            1. 多喝热水。<br>
            2. 带薪拉屎是合法的。<br>
            3. 老板不走我不走 (假的)。
          </p>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref } from 'vue'

// 获取本地存储的角色和名字
// 注意：这里为了兼容，我加了 localStorage 获取名字的逻辑
const role = ref(localStorage.getItem('role') || '游客')
const userRealName = ref(localStorage.getItem('username') || '打工人')

</script>

<style scoped>
.dashboard-container {
  padding: 20px;
  background-color: #f0f2f5; /* 浅灰底色，更有办公氛围 */
  min-height: 85vh;
}

.header-section {
  margin-bottom: 20px;
  color: #303133;
}

.meme-card {
  background: linear-gradient(135deg, #fff 0%, #fdf6ec 100%);
  border: 2px dashed #e6a23c; /* 虚线边框，像便签 */
}

.meme-content {
  text-align: center;
  padding: 10px;
}

.typing-effect {
  font-size: 24px;
  font-weight: bold;
  color: #d03050; /* 醒目的红色 */
  margin-bottom: 20px;
  font-family: 'Courier New', Courier, monospace;
  text-shadow: 2px 2px 0px rgba(0,0,0,0.1);
}

.image-wrapper {
  margin: 20px 0;
  position: relative;
  display: inline-block;
  border: 5px solid #333; /* 相框感 */
  border-radius: 10px;
  background: #fff;
  padding: 5px;
  box-shadow: 5px 5px 15px rgba(0,0,0,0.2);
  transform: rotate(-2deg); /* 稍微歪一点，更有感觉 */
  transition: transform 0.3s;
}

.image-wrapper:hover {
  transform: rotate(0deg) scale(1.02);
}

.cow-img {
  max-width: 100%;
  height: auto;
  max-height: 300px;
  border-radius: 4px;
}

.image-caption {
  font-size: 12px;
  color: #666;
  margin-top: 5px;
  font-style: italic;
}

.fake-stats {
  margin-top: 30px;
  text-align: left;
  background: #fff;
  padding: 15px;
  border-radius: 8px;
}

.stat-item {
  margin-bottom: 15px;
}
.stat-item span {
  font-size: 14px;
  font-weight: bold;
  color: #606266;
  margin-bottom: 5px;
  display: block;
}

/* --- 身份卡片样式 --- */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
}

.avatar-placeholder {
  width: 60px;
  height: 60px;
  background-color: #409eff;
  color: #fff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: bold;
  margin-right: 15px;
}

.info-text h3 {
  margin: 0 0 5px 0;
}
.info-text p {
  margin: 2px 0;
  font-size: 13px;
  color: #909399;
}

.tip-box {
  padding: 15px;
  border-radius: 6px;
  margin-bottom: 10px;
  text-align: center;
}

.admin-tip {
  background-color: #ecf5ff;
  border: 1px solid #d9ecff;
}

.worker-tip {
  background-color: #fdf6ec;
  border: 1px solid #faecd8;
}

.tip-box h4 {
  margin-top: 0;
  margin-bottom: 10px;
}
.tip-box p {
  font-size: 13px;
  color: #666;
  margin-bottom: 15px;
}
/* 在 style 底部新增一个管理员专属的紫色/红色调样式 */
.system-tip {
  background-color: #fef0f0; /* 浅红色 */
  border: 1px solid #fde2e2;
}

.system-tip h4 {
  color: #f56c6c;
}
</style>