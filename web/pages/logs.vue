<script setup lang="ts">
import { adminApi } from '~/composables/useAdminApi'
import { formatTime } from '~/lib/admin'
import type { LogItem } from '~/types/admin'

definePageMeta({
  navKey: 'logs',
})

const admin = useAdminApp()

const items = ref<LogItem[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(25)
const loading = ref(false)
const search = ref('')
const handlerFilter = ref('all')

const filteredItems = computed(() => {
  const query = search.value.trim().toLowerCase()
  return items.value.filter((item) => {
    if (handlerFilter.value !== 'all' && item.handler !== handlerFilter.value) {
      return false
    }
    if (!query) {
      return true
    }
    return [item.handler, item.credential_id, item.text, item.status_code]
      .some((value) => String(value || '').toLowerCase().includes(query))
  })
})

const maxPage = computed(() => Math.max(1, Math.ceil((total.value || 0) / (pageSize.value || 25))))

async function loadLogs(nextPage = page.value, nextPageSize = pageSize.value) {
  loading.value = true
  try {
    const data = await adminApi.listLogs(admin.token.value, { page: nextPage, pageSize: nextPageSize })
    items.value = data.data || []
    total.value = data.total || 0
    page.value = data.page || nextPage
    pageSize.value = data.page_size || nextPageSize
  } catch (error) {
    admin.notify(error instanceof Error ? error.message : '加载日志失败', 'danger')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (admin.authReady.value) {
    void loadLogs()
  }
})

watch(
  () => admin.authReady.value,
  (ready) => {
    if (ready) {
      void loadLogs(1, pageSize.value)
    }
  },
)
</script>

<template>
  <div class="page-grid">
    <PageHeader
      eyebrow="请求记录"
      title="日志排查"
      description="按页查看内存中的近期请求、状态码和错误信息，服务重启后会清空。"
    >
      <template #actions>
        <AdminButton variant="secondary" :disabled="loading" @click="loadLogs(page, pageSize)">
          {{ loading ? '刷新中...' : '刷新当前页' }}
        </AdminButton>
      </template>
    </PageHeader>

    <SectionCard title="筛选" eyebrow="当前页">
      <template #actions>
        <div class="toolbar-inline">
          <input v-model="search" class="search-input" placeholder="筛选处理器 / 凭据 / 文本 / 状态码">
          <select
            class="select-input"
            :value="pageSize"
            @change="loadLogs(1, Number(($event.target as HTMLSelectElement).value))"
          >
            <option :value="25">25 条 / 页</option>
            <option :value="50">50 条 / 页</option>
            <option :value="100">100 条 / 页</option>
          </select>
        </div>
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

    <SectionCard title="日志列表" eyebrow="分页">
      <template #actions>
        <div class="pager">
          <AdminButton variant="ghost" size="sm" :disabled="page <= 1 || loading" @click="loadLogs(Math.max(1, page - 1), pageSize)">
            上一页
          </AdminButton>
          <span>第 {{ page }} / {{ maxPage }} 页</span>
          <AdminButton variant="ghost" size="sm" :disabled="page >= maxPage || loading" @click="loadLogs(Math.min(maxPage, page + 1), pageSize)">
            下一页
          </AdminButton>
        </div>
      </template>

      <div v-if="filteredItems.length" class="log-list">
        <article
          v-for="item in filteredItems"
          :key="`${item.handler}-${item.credential_id}-${item.created_at}-${item.status_code}`"
          class="log-item"
        >
          <div class="log-meta">
            <AdminBadge :tone="item.status_code < 400 ? 'success' : 'danger'">
              {{ item.status_code }}
            </AdminBadge>
            <span>{{ admin.handlerLookup.value.get(item.handler)?.label || item.handler }}</span>
            <span>{{ item.credential_id || '未记录凭据' }}</span>
            <span>{{ formatTime(item.created_at) }}</span>
          </div>
          <div class="log-text">{{ item.text }}</div>
        </article>
      </div>

      <EmptyState
        v-else
        title="这一页没有匹配的日志"
        description="可以切换页码、清空筛选，或等待新的请求进入。"
      />
    </SectionCard>
  </div>
</template>
