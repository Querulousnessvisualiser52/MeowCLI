export default defineNuxtConfig({
  compatibilityDate: '2026-03-10',
  devtools: { enabled: false },
  ssr: true,
  css: ['~/assets/css/main.css'],
  components: [
    {
      path: '~/components',
      pathPrefix: false,
    },
  ],
  app: {
    baseURL: '/admin/',
    buildAssetsDir: 'assets/',
    head: {
      title: 'MeowCLI 管理台',
      htmlAttrs: {
        lang: 'zh-CN',
      },
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'color-scheme', content: 'light dark' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/admin/faction.ico' },
      ],
    },
  },
  nitro: {
    prerender: {
      routes: ['/', '/dashboard', '/settings', '/credentials', '/models', '/logs', '/keys'],
    },
  },
  typescript: {
    strict: true,
    typeCheck: false,
  },
})
