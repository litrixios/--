<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <h2>⚡ 智慧能源管理系统</h2>
        <p>Smart Energy Management System</p>
      </div>

      <el-card shadow="hover">
        <el-form :model="form" :rules="rules" ref="loginFormRef" size="large">

          <el-form-item prop="username">
            <el-input
                v-model="form.username"
                placeholder="请输入账号 (如: worker_wang)"
                prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
                v-model="form.password"
                type="password"
                placeholder="请输入密码 (如: 123456)"
                prefix-icon="Lock"
                show-password
                @keyup.enter="handleLogin"
            />
          </el-form-item>

          <el-button type="primary" :loading="loading" class="login-btn" @click="handleLogin">
            登 录
          </el-button>

        </el-form>
      </el-card>

      <div class="footer">
        © 2025 智慧能源项目组
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import request from '../utils/request' // 👈 引入我们封装好的 axios

const router = useRouter()
const loginFormRef = ref(null)
const loading = ref(false)

// 表单数据
const form = reactive({
  username: '',
  password: ''
})

// 表单验证规则
const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

// 核心登录逻辑
const handleLogin = () => {
  // 1. 先校验表单格式
  loginFormRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true
    try {
      // 📡 2. 发送真实请求给后端
      // 对应后端接口: POST /api/login
      const res = await request.post('/api/login', {
        username: form.username,
        password: form.password
      })

      // ⚠️ 注意：这里 res 的结构取决于 request.js 的拦截器
      // 如果你的拦截器直接返回 response.data，那么 res 就是 { token:..., role_code:... }

      if (res && res.token) {
        ElMessage.success(`欢迎回来，${res.real_name}`)

        // 💾 3. 将关键信息存入浏览器缓存 (LocalStorage)
        localStorage.setItem('token', res.token)
        localStorage.setItem('user_id', res.user_id)
        localStorage.setItem('username', res.real_name)

        // 关键点：后端叫 role_code，前端之前逻辑里用的 key 叫 'role'
        // 所以这里要对应起来，否则菜单显示不出来
        localStorage.setItem('role', res.role_code)

        // 🚀 4. 跳转到首页
        router.push('/')
      } else {
        // 如果后端没报错但也没返回token (预防性判断)
        ElMessage.error('登录异常，未获取到令牌')
      }

    } catch (error) {
      // request.js 里的拦截器通常会打印错误，这里只弹窗提示
      console.error(error)
      // 如果后端返回 400 密码错误，Axios 会在这里捕获到
      ElMessage.error(error.response?.data?.detail || '登录失败，请检查账号密码')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped>
.login-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #2d3a4b 0%, #1f2d3d 100%); /* 深色科技感背景 */
}

.login-box {
  width: 400px;
  text-align: center;
}

.login-header {
  margin-bottom: 40px;
  color: #fff;
}
.login-header h2 { font-size: 28px; margin-bottom: 10px; }
.login-header p { font-size: 14px; opacity: 0.8; }

.login-btn {
  width: 100%;
  font-size: 16px;
  padding: 20px 0;
  margin-top: 10px;
}

.footer {
  margin-top: 20px;
  color: #7d8996;
  font-size: 12px;
}
</style>