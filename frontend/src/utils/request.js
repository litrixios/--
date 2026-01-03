// frontend/src/utils/request.js
import axios from 'axios'
import router from '../router' // 引入路由实例

const service = axios.create({
  baseURL: 'http://127.0.0.1:8000',
  timeout: 5000
})

// 请求拦截器：自动带上 Token
service.interceptors.request.use(
  config => {
    // 假设登录时保存了 token 到 localStorage
    const token = localStorage.getItem('token')
    if (token) {
      config.headers['Authorization'] = 'Bearer ' + token
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    // 【安全功能2：处理会话超时】
    if (error.response && error.response.status === 401) {
      // Token 过期或无效
      console.warn('会话已过期，请重新登录')
      localStorage.removeItem('token')
      localStorage.removeItem('role')
      // 强制跳转回登录页
      router.push('/login')
    }
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

export default service