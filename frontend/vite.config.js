import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      // 这里的 '/api' 对应你 axios.get('/api/...') 的开头
      '/api': {
        target: 'http://localhost:8000', // 填入你刚才找到的后端端口
        changeOrigin: true,
        // 如果你的后端接口路径里本身没有 /api（例如后端是 /admin/user/list）
        // 则需要把 /api 替换掉，取消下面一行的注释：
        // rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  }
})