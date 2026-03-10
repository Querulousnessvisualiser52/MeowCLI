<script setup lang="ts">
defineProps<{
  label: string
  value: string | number
  helper?: string
}>()
</script>

<template>
  <article class="metric-card">
    <div class="metric-label">{{ label }}</div>
    <div class="metric-value">{{ value }}</div>
    <div v-if="helper" class="metric-helper">{{ helper }}</div>
  </article>
</template>
