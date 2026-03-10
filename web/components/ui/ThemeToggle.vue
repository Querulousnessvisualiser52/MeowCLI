<script setup lang="ts">
import type { ThemeMode } from '~/types/admin'

const props = withDefaults(defineProps<{
  theme?: ThemeMode
}>(), {
  theme: 'light',
})

defineEmits<{
  toggle: []
}>()

const nextLabel = computed(() => (
  props.theme === 'dark' ? '切换到浅色模式' : '切换到深色模式'
))
</script>

<template>
  <button
    type="button"
    class="theme-toggle"
    :data-theme="theme"
    :aria-label="nextLabel"
    :title="nextLabel"
    @click="$emit('toggle')"
  >
    <span class="theme-toggle-track">
      <span class="theme-toggle-thumb" />
    </span>
    <span class="theme-toggle-copy">{{ theme === 'dark' ? '深色' : '浅色' }}</span>
  </button>
</template>
