<script setup lang="ts">
defineProps<{
  title?: string
  eyebrow?: string
  className?: string
}>()
</script>

<template>
  <section :class="['section-card', className]">
    <header v-if="title || eyebrow || $slots.actions" class="section-head">
      <div>
        <div v-if="eyebrow" class="eyebrow">{{ eyebrow }}</div>
        <h2 v-if="title">{{ title }}</h2>
      </div>
      <div v-if="$slots.actions" class="section-actions">
        <slot name="actions" />
      </div>
    </header>
    <slot />
  </section>
</template>
