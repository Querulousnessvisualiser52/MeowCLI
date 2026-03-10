<script setup lang="ts">
import { adminApi } from '~/composables/useAdminApi'
import { formatTime, roleText } from '~/lib/admin'
import type { AuthKeyItem } from '~/types/admin'

definePageMeta({
  navKey: 'keys',
})

const admin = useAdminApp()

const items = ref<AuthKeyItem[]>([])
const loading = ref(false)
const actionBusy = ref(false)
const roleDrafts = ref<Record<string, string>>({})
const noteDrafts = ref<Record<string, string>>({})

const modalOpen = ref(false)
const modalKey = ref('')
const modalRole = ref('user')
const modalNote = ref('')
const modalError = ref('')

const confirmOpen = ref(false)
const confirmTitle = ref('')
const confirmMessage = ref('')
const confirmText = ref('确认')
let confirmAction: null | (() => Promise<void>) = null

const ROLE_OPTIONS = [
  { value: 'user', label: '普通成员' },
  { value: 'admin', label: '管理员' },
] as const

function syncRoleDrafts(nextItems: AuthKeyItem[]) {
  roleDrafts.value = Object.fromEntries(nextItems.map((item) => [item.key, item.role]))
  noteDrafts.value = Object.fromEntries(nextItems.map((item) => [item.key, item.note || '']))
}

async function loadAuthKeys() {
  loading.value = true
  try {
    items.value = await adminApi.listAuthKeys(admin.token.value)
    syncRoleDrafts(items.value)
  } catch (error) {
    admin.notify(error instanceof Error ? error.message : '加载密钥失败', 'danger')
  } finally {
    loading.value = false
  }
}

function openCreateModal() {
  modalOpen.value = true
  modalKey.value = ''
  modalRole.value = 'user'
  modalNote.value = ''
  modalError.value = ''
}

function closeModal() {
  modalOpen.value = false
  modalError.value = ''
}

async function createAuthKey() {
  actionBusy.value = true
  try {
    const payload: { key?: string; role: string; note: string } = {
      role: modalRole.value,
      note: modalNote.value.trim(),
    }
    if (modalKey.value.trim()) {
      payload.key = modalKey.value.trim()
    }
    await adminApi.createAuthKey(admin.token.value, payload)
    closeModal()
    admin.notify('密钥已创建')
    await Promise.all([
      admin.loadOverview(admin.token.value, true),
      loadAuthKeys(),
    ])
  } catch (error) {
    modalError.value = error instanceof Error ? error.message : '创建密钥失败'
  } finally {
    actionBusy.value = false
  }
}

function openConfirm(options: { title: string; message: string; confirmText: string; action: () => Promise<void> }) {
  confirmTitle.value = options.title
  confirmMessage.value = options.message
  confirmText.value = options.confirmText
  confirmAction = options.action
  confirmOpen.value = true
}

function selectedRole(item: typeof items.value[number]) {
  return roleDrafts.value[item.key] || item.role
}

function roleChanged(item: typeof items.value[number]) {
  return selectedRole(item) !== item.role
}

function selectedNote(item: typeof items.value[number]) {
  return noteDrafts.value[item.key] ?? item.note ?? ''
}

function noteChanged(item: typeof items.value[number]) {
  return selectedNote(item).trim() !== (item.note || '').trim()
}

function itemChanged(item: typeof items.value[number]) {
  return roleChanged(item) || noteChanged(item)
}

async function copyAuthKey(value: string) {
  if (!import.meta.client) {
    return
  }

  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(value)
    } else {
      const helper = document.createElement('textarea')
      helper.value = value
      helper.setAttribute('readonly', 'true')
      helper.style.position = 'fixed'
      helper.style.opacity = '0'
      document.body.appendChild(helper)
      helper.select()
      document.execCommand('copy')
      document.body.removeChild(helper)
    }
    admin.notify('密钥已复制')
  } catch {
    admin.notify('复制失败，请手动复制', 'warning')
  }
}

function updateAuthKey(item: typeof items.value[number]) {
  const nextRole = selectedRole(item)
  const nextNote = selectedNote(item).trim()
  if (nextRole === item.role && nextNote === (item.note || '').trim()) {
    return
  }

  openConfirm({
    title: '保存密钥设置',
    message: `确认保存 ${item.key} 的角色和备注修改吗？`,
    confirmText: '确认保存',
    action: async () => {
      actionBusy.value = true
      try {
        await adminApi.updateAuthKey(admin.token.value, item.key, {
          role: nextRole,
          note: nextNote,
        })
        admin.notify('密钥设置已更新')
        await Promise.all([
          admin.loadOverview(admin.token.value, true),
          loadAuthKeys(),
        ])
      } catch (error) {
        admin.notify(error instanceof Error ? error.message : '更新密钥失败', 'danger')
        roleDrafts.value[item.key] = item.role
        noteDrafts.value[item.key] = item.note || ''
      } finally {
        actionBusy.value = false
      }
    },
  })
}

function deleteAuthKey(item: typeof items.value[number]) {
  openConfirm({
    title: '删除 API 密钥',
    message: `确认删除密钥 ${item.key} 吗？此操作不可撤销。`,
    confirmText: '确认删除',
    action: async () => {
      actionBusy.value = true
      try {
        await adminApi.deleteAuthKey(admin.token.value, item.key)
        admin.notify('密钥已删除')
        await Promise.all([
          admin.loadOverview(admin.token.value, true),
          loadAuthKeys(),
        ])
      } catch (error) {
        admin.notify(error instanceof Error ? error.message : '删除密钥失败', 'danger')
      } finally {
        actionBusy.value = false
      }
    },
  })
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
    void loadAuthKeys()
  }
})

watch(
  () => admin.authReady.value,
  (ready) => {
    if (ready) {
      void loadAuthKeys()
    }
  },
)
</script>

<template>
  <div class="page-grid">
    <PageHeader
      eyebrow="访问控制"
      title="API 密钥"
      description="统一管理后台和 API 的访问密钥，并控制角色权限。"
    >
      <template #actions>
        <AdminButton variant="secondary" :disabled="loading" @click="loadAuthKeys">
          {{ loading ? '刷新中...' : '刷新列表' }}
        </AdminButton>
        <AdminButton @click="openCreateModal">新建密钥</AdminButton>
      </template>
    </PageHeader>

    <SectionCard title="密钥列表" :eyebrow="`${items.length} 把密钥`">
      <div v-if="items.length" class="key-list">
        <article v-for="item in items" :key="item.key" class="key-item-card">
          <div class="key-item-main">
            <button type="button" class="key-copy-button" :title="`点击复制 ${item.key}`" @click="copyAuthKey(item.key)">
              <span class="eyebrow">点击复制密钥</span>
              <code class="key-code">{{ item.key }}</code>
            </button>
            <div class="key-meta-row">
              <AdminBadge :tone="item.role === 'admin' ? 'warning' : 'success'">
                {{ roleText(item.role) }}
              </AdminBadge>
              <span class="text-muted">创建于 {{ formatTime(item.created_at) }}</span>
            </div>
            <label class="form-field key-note-editor">
              <span>备注</span>
              <input
                :value="selectedNote(item)"
                type="text"
                placeholder="输入这把密钥的用途，例如 CI / 本地开发"
                @input="noteDrafts[item.key] = ($event.target as HTMLInputElement).value"
              >
            </label>
          </div>

          <div class="key-item-side">
            <label class="form-field key-role-editor">
              <span>角色</span>
              <select
                class="select-input role-select"
                :value="selectedRole(item)"
                @change="roleDrafts[item.key] = ($event.target as HTMLSelectElement).value"
              >
                <option v-for="option in ROLE_OPTIONS" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </label>

            <div class="key-item-actions">
              <AdminButton
                variant="secondary"
                size="sm"
                :disabled="actionBusy || !itemChanged(item)"
                @click="updateAuthKey(item)"
              >
                保存修改
              </AdminButton>
              <AdminButton variant="danger" size="sm" :disabled="actionBusy" @click="deleteAuthKey(item)">删除</AdminButton>
            </div>
          </div>
        </article>
      </div>

      <EmptyState
        v-else
        title="还没有 API 密钥"
        description="创建一把密钥后，就可以用于后台或接口访问。"
      />
    </SectionCard>

    <ModalDialog :open="modalOpen" title="新建 API 密钥" @close="closeModal">
      <div class="form-grid">
        <label class="form-field">
          <span>自定义密钥<small>可选</small></span>
          <input v-model="modalKey" placeholder="留空时自动生成 sk-...">
          <small>不填写时系统会自动生成新密钥。</small>
        </label>
        <label class="form-field">
          <span>角色</span>
          <select v-model="modalRole" class="select-input">
            <option value="user">普通成员</option>
            <option value="admin">管理员</option>
          </select>
          <small>管理员拥有更高的后台访问权限。</small>
        </label>
        <label class="form-field">
          <span>备注<small>可选</small></span>
          <input v-model="modalNote" placeholder="例如：CI 或本地开发">
          <small>便于区分用途，不参与鉴权。</small>
        </label>
        <div v-if="modalError" class="form-error">{{ modalError }}</div>
      </div>
      <template #footer>
        <AdminButton variant="ghost" @click="closeModal">取消</AdminButton>
        <AdminButton :disabled="actionBusy" @click="createAuthKey">
          {{ actionBusy ? '创建中...' : '创建密钥' }}
        </AdminButton>
      </template>
    </ModalDialog>

    <ModalDialog :open="confirmOpen" :title="confirmTitle" @close="confirmOpen = false">
      <p>{{ confirmMessage }}</p>
      <template #footer>
        <AdminButton variant="ghost" :disabled="actionBusy" @click="confirmOpen = false">取消</AdminButton>
        <AdminButton variant="danger" :disabled="actionBusy" @click="submitConfirm">{{ confirmText }}</AdminButton>
      </template>
    </ModalDialog>
  </div>
</template>
