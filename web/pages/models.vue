<script setup lang="ts">
import { adminApi } from '~/composables/useAdminApi'
import { safeStringify, statusText, toneForStatus } from '~/lib/admin'
import type { ModelItem } from '~/types/admin'

definePageMeta({
  navKey: 'models',
})

const admin = useAdminApp()

const items = ref<ModelItem[]>([])
const loading = ref(false)
const search = ref('')
const handlerFilter = ref('all')
const actionBusy = ref(false)

const modalOpen = ref(false)
const modalMode = ref<'create' | 'edit'>('create')
const modalAlias = ref('')
const modalOrigin = ref('')
const modalHandler = ref('codex')
const modalExtra = ref('{}')
const modalError = ref('')

const confirmOpen = ref(false)
const confirmTitle = ref('')
const confirmMessage = ref('')
let confirmAction: null | (() => Promise<void>) = null

const filteredItems = computed(() => {
  const query = search.value.trim().toLowerCase()
  return items.value.filter((item) => {
    if (handlerFilter.value !== 'all' && item.handler !== handlerFilter.value) {
      return false
    }
    if (!query) {
      return true
    }
    return [item.alias, item.origin, item.handler, safeStringify(item.extra)]
      .some((value) => String(value || '').toLowerCase().includes(query))
  })
})

async function loadModels() {
  loading.value = true
  try {
    items.value = await adminApi.listModels(admin.token.value)
  } catch (error) {
    admin.notify(error instanceof Error ? error.message : '加载模型映射失败', 'danger')
  } finally {
    loading.value = false
  }
}

function openCreateModal() {
  modalMode.value = 'create'
  modalAlias.value = ''
  modalOrigin.value = ''
  modalHandler.value = admin.activeHandler.value?.key || admin.handlers.value[0]?.key || 'codex'
  modalExtra.value = '{}'
  modalError.value = ''
  modalOpen.value = true
}

function openEditModal(item: typeof items.value[number]) {
  modalMode.value = 'edit'
  modalAlias.value = item.alias
  modalOrigin.value = item.origin
  modalHandler.value = item.handler
  modalExtra.value = safeStringify(item.extra)
  modalError.value = ''
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
  modalError.value = ''
}

async function saveModel() {
  actionBusy.value = true
  try {
    let extra: Record<string, unknown> = {}
    try {
      extra = JSON.parse(modalExtra.value || '{}') as Record<string, unknown>
    } catch {
      throw new Error('附加参数必须是合法的 JSON')
    }

    const payload = {
      origin: modalOrigin.value.trim(),
      handler: modalHandler.value,
      extra,
    }

    if (modalMode.value === 'edit') {
      await adminApi.updateModel(admin.token.value, modalAlias.value, payload)
    } else {
      await adminApi.createModel(admin.token.value, {
        alias: modalAlias.value.trim(),
        ...payload,
      })
    }

    closeModal()
    admin.notify(modalMode.value === 'edit' ? '模型映射已更新' : '模型映射已创建')
    await Promise.all([
      admin.loadOverview(admin.token.value, true),
      loadModels(),
    ])
  } catch (error) {
    modalError.value = error instanceof Error ? error.message : '保存模型映射失败'
  } finally {
    actionBusy.value = false
  }
}

function openDeleteConfirm(item: typeof items.value[number]) {
  confirmTitle.value = '删除模型映射'
  confirmMessage.value = `确认删除模型映射“${item.alias}”吗？`
  confirmAction = async () => {
    actionBusy.value = true
    try {
      await adminApi.deleteModel(admin.token.value, item.alias)
      admin.notify('模型映射已删除')
      await Promise.all([
        admin.loadOverview(admin.token.value, true),
        loadModels(),
      ])
    } catch (error) {
      admin.notify(error instanceof Error ? error.message : '删除模型映射失败', 'danger')
    } finally {
      actionBusy.value = false
    }
  }
  confirmOpen.value = true
}

async function submitConfirm() {
  if (!confirmAction || actionBusy.value) {
    return
  }
  const action = confirmAction
  confirmOpen.value = false
  confirmAction = null
  await action()
}

onMounted(() => {
  if (admin.authReady.value) {
    void loadModels()
  }
})

watch(
  () => admin.authReady.value,
  (ready) => {
    if (ready) {
      void loadModels()
    }
  },
)
</script>

<template>
  <div class="page-grid">
    <PageHeader
      eyebrow="别名映射"
      title="模型管理"
      description="把对外暴露的模型别名映射到上游模型，便于统一路由。"
    >
      <template #actions>
        <AdminButton variant="secondary" :disabled="loading" @click="loadModels">
          {{ loading ? '刷新中...' : '刷新列表' }}
        </AdminButton>
        <AdminButton @click="openCreateModal">新建映射</AdminButton>
      </template>
    </PageHeader>

    <SectionCard title="筛选" eyebrow="浏览">
      <template #actions>
        <input v-model="search" class="search-input" placeholder="搜索别名 / 上游模型 / 附加参数">
      </template>
      <div class="chip-row">
        <button type="button" :class="['chip', { 'is-active': handlerFilter === 'all' }]" @click="handlerFilter = 'all'">
          全部
        </button>
        <button
          v-for="handler in admin.handlers.value"
          :key="handler.key"
          type="button"
          :class="['chip', { 'is-active': handlerFilter === handler.key }]"
          @click="handlerFilter = handler.key"
        >
          {{ handler.label }}
        </button>
      </div>
    </SectionCard>

    <SectionCard title="映射列表" :eyebrow="`${filteredItems.length} 条结果`">
      <div v-if="filteredItems.length" class="table-shell">
        <table>
          <thead>
            <tr>
              <th>别名</th>
              <th>上游模型</th>
              <th>处理器</th>
              <th>附加参数</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredItems" :key="item.alias">
              <td>{{ item.alias }}</td>
              <td>{{ item.origin }}</td>
              <td>
                <AdminBadge :tone="toneForStatus(admin.handlerLookup.value.get(item.handler)?.status || 'planned')">
                  {{ admin.handlerLookup.value.get(item.handler)?.label || item.handler }}
                </AdminBadge>
              </td>
              <td><code class="code-inline">{{ safeStringify(item.extra) }}</code></td>
              <td class="table-actions">
                <AdminButton variant="ghost" size="sm" @click="openEditModal(item)">编辑</AdminButton>
                <AdminButton variant="danger" size="sm" :disabled="actionBusy" @click="openDeleteConfirm(item)">删除</AdminButton>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <EmptyState
        v-else
        title="没有符合条件的映射"
        description="调整筛选条件，或先创建新的模型别名。"
      />
    </SectionCard>

    <ModalDialog :open="modalOpen" :title="modalMode === 'edit' ? '编辑模型映射' : '新建模型映射'" @close="closeModal">
      <div class="form-grid">
        <label class="form-field">
          <span>模型别名</span>
          <input v-model="modalAlias" :disabled="modalMode === 'edit'">
          <small>创建后别名不可修改。</small>
        </label>
        <label class="form-field">
          <span>上游模型</span>
          <input v-model="modalOrigin">
          <small>实际请求上游时使用的模型名称。</small>
        </label>
        <label class="form-field">
          <span>处理器</span>
          <select v-model="modalHandler" class="select-input">
            <option v-for="handler in admin.handlers.value" :key="handler.key" :value="handler.key">
              {{ handler.label }}（{{ statusText(handler.status) }}）
            </option>
          </select>
          <small>决定这条映射交给哪个处理器。</small>
        </label>
        <label class="form-field">
          <span>附加参数 JSON</span>
          <textarea v-model="modalExtra" rows="5" />
          <small>用于保存额外的路由参数，默认可留空对象。</small>
        </label>
        <div v-if="modalError" class="form-error">{{ modalError }}</div>
      </div>
      <template #footer>
        <AdminButton variant="ghost" @click="closeModal">取消</AdminButton>
        <AdminButton :disabled="actionBusy" @click="saveModel">
          {{ actionBusy ? '保存中...' : '保存' }}
        </AdminButton>
      </template>
    </ModalDialog>

    <ModalDialog :open="confirmOpen" :title="confirmTitle" @close="confirmOpen = false">
      <p>{{ confirmMessage }}</p>
      <template #footer>
        <AdminButton variant="ghost" :disabled="actionBusy" @click="confirmOpen = false">取消</AdminButton>
        <AdminButton variant="danger" :disabled="actionBusy" @click="submitConfirm">确认删除</AdminButton>
      </template>
    </ModalDialog>
  </div>
</template>
