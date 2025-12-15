import axios from 'axios'

const service = axios.create({
  baseURL: 'http://127.0.0.1:8000', // 你的 FastAPI 地址
  timeout: 5000
})

// 响应拦截器：简化数据返回
service.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

export default service