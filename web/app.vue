<script setup lang="ts">
import { AUTH_INVALID_EVENT } from '~/composables/useAdminApi'
import {
  NAV_ITEMS,
  THEME_STORAGE_KEY,
  applyTheme,
} from '~/lib/admin'

const admin = useAdminApp()
const route = useRoute()
const router = useRouter()
const clientReady = ref(false)
const sessionReady = ref(false)
const runtimeConfig = useRuntimeConfig()

const faviconPath = computed(() => `${runtimeConfig.app.baseURL}faction.ico`)

const currentNav = computed(() => {
  const routeKey = String(route.meta.navKey || 'dashboard')
  return NAV_ITEMS.find((item) => item.key === routeKey) || NAV_ITEMS[0]
})

const quickStats = computed(() => {
  const summary = admin.overview.value.summary

  return [
    {
      label: '处理器',
      value: String(admin.handlers.value.length || 0).padStart(2, '0'),
    },
    {
      label: '凭据',
      value: String(summary.credentials_total || 0).padStart(2, '0'),
    },
    {
      label: '模型',
      value: String(summary.models_total || 0).padStart(2, '0'),
    },
  ]
})

const pageTitle = computed(() => {
  if (!admin.authReady.value) {
    return 'MeowCLI 管理台'
  }
  return `${currentNav.value.label} | MeowCLI 管理台`
})

useHead(() => ({
  title: pageTitle.value,
}))

function persistTheme(theme: string) {
  if (!import.meta.client) {
    return
  }

  applyTheme(theme as 'light' | 'dark')
  window.localStorage.setItem(THEME_STORAGE_KEY, theme)
}

async function handleLogin() {
  if (await admin.submitLogin()) {
    await router.push('/')
  }
}

function handleAuthInvalid() {
  admin.resetAuthState('管理员密钥无效或已失效')
}

let toastTimer: ReturnType<typeof window.setTimeout> | undefined

watch(
  () => admin.theme.value,
  (theme) => {
    if (!import.meta.client || !clientReady.value) {
      return
    }
    persistTheme(theme)
  },
)

watch(
  () => admin.toast.value,
  (toast) => {
    if (!import.meta.client) {
      return
    }
    if (toastTimer) {
      window.clearTimeout(toastTimer)
    }
    if (toast) {
      toastTimer = window.setTimeout(() => admin.dismissToast(), 2400)
    }
  },
)

onMounted(() => {
  admin.initializeClient()
  clientReady.value = true
  persistTheme(admin.theme.value)
  window.addEventListener(AUTH_INVALID_EVENT, handleAuthInvalid)

  void (async () => {
    try {
      await admin.boot()
    } finally {
      sessionReady.value = true
    }
  })()
})

onBeforeUnmount(() => {
  if (!import.meta.client) {
    return
  }
  window.removeEventListener(AUTH_INVALID_EVENT, handleAuthInvalid)
  if (toastTimer) {
    window.clearTimeout(toastTimer)
  }
})
</script>

<template>
  <div class="app-host">
    <Transition name="fade-up">
      <div v-if="admin.toast.value" :class="['toast', `toast-${admin.toast.value.tone}`]">
        {{ admin.toast.value.text }}
      </div>
    </Transition>

    <template v-if="!clientReady || !sessionReady">
      <main class="loading-screen">
        <section class="loading-card">
          <div class="loading-brand">
            <div class="brand-mark brand-mark-large">
              <img class="brand-mark-image" :src="faviconPath" alt="" aria-hidden="true">
            </div>
            <div>
              <div class="brand-title">MeowCLI</div>
              <div class="brand-subtitle">正在恢复控制台会话</div>
            </div>
          </div>

          <div class="loading-copy">
            <div class="login-chip">MEOWCLI / ADMIN</div>
            <h1>正在检查本地密钥与后台状态</h1>
            <p>首屏会先展示这个中性壳层，等鉴权恢复完成后再进入登录页或后台，避免闪出未登录场景。</p>
          </div>

          <div class="loading-bar" aria-hidden="true">
            <span />
          </div>
        </section>
      </main>
    </template>

    <template v-else-if="!admin.authReady.value">
      <main class="login-screen">
        <div class="theme-float">
          <ThemeToggle :theme="admin.theme.value" @toggle="admin.toggleTheme()" />
        </div>

        <div class="login-stage">
          <section class="login-hero">
            <div class="login-hero-brand">
              <div class="brand-mark brand-mark-large">
                <img class="brand-mark-image" :src="faviconPath" alt="" aria-hidden="true">
              </div>
              <div>
                <div class="brand-title">MeowCLI</div>
                <div class="brand-subtitle">单机部署 · 轻量控制面</div>
              </div>
            </div>

            <div class="login-hero-copy">
              <div class="login-chip">MEOWCLI / ADMIN</div>
              <h1>把凭据、模型和访问控制收进一个更轻、更顺手的后台。</h1>
              <p class="login-hero-note">
                静态生成前端，适合本地运行和单二进制部署。进入后即可统一管理 CLI 令牌池、模型映射、日志与访问密钥。
              </p>
            </div>

            <div class="login-feature-grid">
              <article class="login-feature">
                <strong>凭据池</strong>
                <span>批量导入、启停和配额同步都集中在一个面板里。</span>
              </article>
              <article class="login-feature">
                <strong>模型路由</strong>
                <span>把别名、上游模型和处理器映射关系拆开管理。</span>
              </article>
              <article class="login-feature">
                <strong>访问控制</strong>
                <span>后台与 API 使用同一套密钥体系，便于角色区分。</span>
              </article>
            </div>
          </section>

          <section class="login-card">
            <template v-if="admin.setupDone.value && admin.setupResult.value">
              <div class="login-chip">MeowCLI 管理台</div>
              <h1>初始化完成</h1>
              <p>请立即保存新生成的管理员密钥。页面关闭后，这个密钥不会再次显示。</p>
              <div class="setup-key-display">
                <code>{{ admin.setupResult.value.key }}</code>
              </div>
              <p class="login-note">
                角色：{{ admin.setupResult.value.role }}<span v-if="admin.setupResult.value.note"> · 备注：{{ admin.setupResult.value.note }}</span>
              </p>
              <div v-if="admin.loginError.value" class="form-error">{{ admin.loginError.value }}</div>
              <AdminButton block :disabled="admin.booting.value" @click="handleLogin">
                {{ admin.booting.value ? '验证中...' : '使用该密钥进入管理台' }}
              </AdminButton>
            </template>

            <template v-else-if="admin.needSetup.value">
              <div class="login-chip">首次启动</div>
              <h1>创建首个管理员密钥</h1>
              <p>系统尚未配置后台密钥。先创建一个管理员密钥，再进入管理台。</p>
              <form class="login-form" @submit.prevent="admin.setupAdmin()">
                <label>
                  <span>自定义密钥<small>可选</small></span>
                  <input
                    v-model="admin.setupState.value.key"
                    type="text"
                    placeholder="留空时自动生成 sk-..."
                  >
                </label>
                <label>
                  <span>备注<small>可选</small></span>
                  <input
                    v-model="admin.setupState.value.note"
                    type="text"
                    placeholder="例如：本地管理员"
                  >
                </label>
                <div v-if="admin.loginError.value" class="form-error">{{ admin.loginError.value }}</div>
                <AdminButton type="submit" block :disabled="admin.booting.value">
                  {{ admin.booting.value ? '创建中...' : '创建管理员密钥' }}
                </AdminButton>
              </form>
            </template>

            <template v-else>
              <div class="login-chip">MeowCLI 管理台</div>
              <h1>进入控制台</h1>
              <p>输入管理员密钥后，即可管理凭据、模型映射、日志和访问密钥。</p>
              <form class="login-form" @submit.prevent="handleLogin">
                <label>
                  <span>管理员密钥</span>
                  <input
                    v-model="admin.loginInput.value"
                    type="password"
                    placeholder="sk-..."
                    autocomplete="current-password"
                  >
                </label>
                <div v-if="admin.loginError.value" class="form-error">{{ admin.loginError.value }}</div>
                <AdminButton type="submit" block :disabled="admin.booting.value">
                  {{ admin.booting.value ? '验证中...' : '登录' }}
                </AdminButton>
              </form>
            </template>
          </section>
        </div>
      </main>
    </template>

    <template v-else>
      <div class="app-shell">
        <aside class="nav-rail">
          <div class="nav-rail-panel">
            <div class="brand-block">
              <div class="brand-mark">
                <img class="brand-mark-image" :src="faviconPath" alt="" aria-hidden="true">
              </div>
              <div>
                <div class="brand-title">MeowCLI</div>
                <div class="brand-subtitle">管理控制台</div>
              </div>
            </div>

            <nav class="nav-list">
              <NuxtLink
                v-for="(item, index) in NAV_ITEMS"
                :key="item.key"
                :to="item.to"
                :class="['nav-item', { 'is-active': currentNav.key === item.key }]"
              >
                <span class="nav-index">{{ String(index + 1).padStart(2, '0') }}</span>
                <span class="nav-copy">
                  <strong>{{ item.label }}</strong>
                  <small>{{ item.eyebrow }}</small>
                </span>
              </NuxtLink>
            </nav>

            <div class="rail-summary">
              <div class="rail-summary-label">运行摘要</div>
              <div class="rail-summary-grid">
                <div v-for="stat in quickStats" :key="stat.label" class="rail-stat">
                  <span>{{ stat.label }}</span>
                  <strong>{{ stat.value }}</strong>
                </div>
              </div>
            </div>
          </div>
        </aside>

        <main class="content-shell">
          <header class="shell-toolbar">
            <div class="shell-breadcrumb">
              <div class="eyebrow">MeowCLI 管理台 / {{ currentNav.eyebrow }}</div>
              <div class="shell-title-row">
                <div class="shell-title">{{ currentNav.label }}</div>
                <div class="shell-status">已连接 {{ admin.handlers.value.length }} 个处理器</div>
              </div>
              <p class="shell-subtitle">{{ currentNav.description }}</p>
            </div>
            <div class="shell-toolbar-actions">
              <ThemeToggle :theme="admin.theme.value" @toggle="admin.toggleTheme()" />
              <AdminButton variant="ghost" @click="admin.logout()">退出登录</AdminButton>
            </div>
          </header>

          <div class="content-panel">
            <NuxtPage />
          </div>
        </main>
      </div>
    </template>
  </div>
</template>
