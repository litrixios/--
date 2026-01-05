<template>
  <div class="admin-content">
    <el-card shadow="never">
      <div class="table-operations">
        <el-button type="primary" @click="openAddUser">新增用户</el-button>
        <el-select v-model="roleFilter" placeholder="角色筛选" clearable @change="fetchUsers" style="width: 200px; margin-left: 10px;">
          <el-option label="系统管理员" value="Admin" />
          <el-option label="运维人员" value="Maintainer" />
          <el-option label="工单管理员" value="WorkOrderAdmin" />
        </el-select>
      </div>

      <el-table :data="userList" border stripe style="width: 100%; margin-top: 15px;">
        <el-table-column prop="UserId" label="ID" width="70" />
        <el-table-column prop="UserName" label="用户名" />
        <el-table-column prop="RealName" label="真实姓名" />
        <el-table-column prop="Phone" label="手机号" />
        <el-table-column prop="RoleCode" label="角色" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.IsLocked ? 'danger' : 'success'">
              {{ scope.row.IsLocked ? '已锁定' : '正常' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="420" fixed="right">
          <template #default="scope">
            <el-button size="small" type="primary" @click="handleEdit(scope.row)">修改</el-button>

            <el-button size="small" type="warning" @click="handleAssignPermission(scope.row)">权限分配</el-button>

            <el-button size="small" :type="scope.row.IsLocked ? 'warning' : 'danger'" @click="toggleLock(scope.row)">
              {{ scope.row.IsLocked ? '解锁' : '锁定' }}
            </el-button>
            <el-button size="small" type="info" @click="handleResetPwd(scope.row)">重置密码</el-button>
            <el-button size="small" type="danger" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="userDialogVisible" :title="isEdit ? '修改用户信息' : '新增用户'">
      <el-form :model="userForm" label-width="80px">
        <el-form-item label="用户名">
          <el-input v-model="userForm.user_name" :disabled="isEdit" placeholder="建议使用工号或拼音" />
        </el-form-item>
        <el-form-item label="真实姓名">
          <el-input v-model="userForm.real_name" />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="密码">
          <el-input v-model="userForm.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="userForm.phone" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="userForm.role_code" style="width: 100%">
            <el-option label="系统管理员" value="Admin" />
            <el-option label="运维人员" value="Operator" />
            <el-option label="工单管理员" value="WorkOrderAdmin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitUser">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="scopeDialogVisible" title="分配管辖权限" width="500px">
      <el-tabs type="border-card">
        <el-tab-pane label="管辖工厂">
          <el-checkbox-group v-model="selectedKeys.Factory">
            <el-checkbox v-for="f in allObjects.factories" :key="f.id" :label="f.id">
              {{ f.name }}
            </el-checkbox>
          </el-checkbox-group>
        </el-tab-pane>

        <el-tab-pane label="管辖配电房">
          <el-checkbox-group v-model="selectedKeys.Substation">
            <el-checkbox v-for="s in allObjects.substations" :key="s.id" :label="s.id">
              {{ s.name }}
            </el-checkbox>
          </el-checkbox-group>
        </el-tab-pane>

        <el-tab-pane label="光伏并网点">
          <el-checkbox-group v-model="selectedKeys.PvGridPoint">
            <el-checkbox v-for="p in allObjects.pv_points" :key="p.id" :label="p.id">
              {{ p.name }}
            </el-checkbox>
          </el-checkbox-group>
        </el-tab-pane>
      </el-tabs>
      <template #footer>
        <el-button @click="scopeDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitScopePermission">确认分配</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import axios from '../../utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

// --- 用户管理逻辑 ---
const userList = ref([])
const roleFilter = ref('')
const userDialogVisible = ref(false)
const isEdit = ref(false)

const userForm = reactive({
  user_id: null,
  user_name: '',
  real_name: '',
  password: '',
  phone: '',
  role_code: 'Operator'
})

const fetchUsers = async () => {
  try {
    // res 已经是拦截器脱壳后的数据（即后端返回的列表）
    const res = await axios.get('/api/admin/user/list', {
      params: { role_filter: roleFilter.value }
    })

    // 如果你的 request.js 已经返回了 response.data，这里直接赋值 res
    userList.value = res

    // 调试用：如果控制台打印的是数组，说明赋值成功
    console.log('用户列表：', res)
  } catch (error) {
    console.error('获取失败:', error)
    ElMessage.error('权限不足或登录过期')
  }
}

const openAddUser = () => {
  isEdit.value = false
  Object.assign(userForm, { user_id: null, user_name: '', real_name: '', password: '', phone: '', role_code: 'Operator' })
  userDialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  userForm.user_id = row.UserId
  userForm.user_name = row.UserName
  userForm.real_name = row.RealName
  userForm.phone = row.Phone
  userForm.role_code = row.RoleCode
  userDialogVisible.value = true
}

const submitUser = async () => {
  try {
    if (isEdit.value) {
      await axios.put('/api/admin/user/update', userForm)
      ElMessage.success('更新成功')
    } else {
      await axios.post('/api/admin/user/add', userForm)
      ElMessage.success('创建成功')
    }
    userDialogVisible.value = false
    fetchUsers()
  } catch (error) { ElMessage.error('操作失败') }
}

const toggleLock = async (user) => {
  await axios.post('/api/admin/user/lock', { user_id: user.UserId, is_locked: !user.IsLocked })
  ElMessage.success('状态已更新')
  fetchUsers()
}

const handleDelete = (row) => {
  ElMessageBox.confirm(`确定要删除用户 ${row.UserName} 吗？`, '警告', { type: 'warning' }).then(async () => {
    await axios.delete(`/api/admin/user/delete/${row.UserId}`)
    ElMessage.success('删除成功')
    fetchUsers()
  })
}

const handleResetPwd = async (row) => {
  await axios.post('/api/admin/user/reset-pwd', { user_id: row.UserId })
  ElMessage.success('密码已重置为 123456')
}

// --- 权限分配逻辑 ---
const scopeDialogVisible = ref(false)
const currentEditUserId = ref(null)
const allObjects = ref({ factories: [], substations: [], pv_points: [] })
const selectedKeys = reactive({ Factory: [], Substation: [], PvGridPoint: [] })

const handleAssignPermission = async (row) => {
  currentEditUserId.value = row.UserId
  try {
    // 1. 获取所有可选资源
    // ✅ 修复：resObj 已经是后端返回的对象 {factories: [], ...}
    const resObj = await axios.get('/api/admin/permission/objects')
    allObjects.value = resObj

    // 2. 重置选中状态
    selectedKeys.Factory = []
    selectedKeys.Substation = []
    selectedKeys.PvGridPoint = []

    // 3. 获取该用户已有权限
    // ✅ 修复：resAuth 已经是后端返回的数组 [{}, {}]
    const resAuth = await axios.get(`/api/admin/user/permissions/${row.UserId}`)

    // 4. 只有当返回的是数组时才遍历
    if (Array.isArray(resAuth)) {
      resAuth.forEach(item => {
        // 注意：item.ObjectType 必须与 selectedKeys 的 key 大小写完全一致
        if (selectedKeys[item.ObjectType]) {
          selectedKeys[item.ObjectType].push(item.ObjectId)
        }
      })
    }

    scopeDialogVisible.value = true
  } catch (error) {
    console.error('加载权限数据失败:', error)
    ElMessage.error('加载权限数据失败')
  }
}

const submitScopePermission = async () => {
  try {
    // 循环提交三种类型的权限分配（或者你可以合并成一个接口）
    const types = ['Factory', 'Substation', 'PvGridPoint']
    for (const type of types) {
      await axios.post('/api/admin/user/assign-scope', {
        user_id: currentEditUserId.value,
        object_type: type,
        object_ids: selectedKeys[type]
      })
    }
    ElMessage.success('权限分配已保存')
    scopeDialogVisible.value = false
  } catch (error) {
    ElMessage.error('保存权限失败')
  }
}

onMounted(fetchUsers)
</script>

<style scoped>
.table-operations { margin-bottom: 20px; }
.admin-content { padding: 20px; }
</style>