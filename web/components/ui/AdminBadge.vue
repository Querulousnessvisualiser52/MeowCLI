<script setup lang="ts">
import type { UiTone } from '~/types/admin'

withDefaults(defineProps<{
  tone?: UiTone
  subtle?: boolean
}>(), {
  tone: 'neutral',
  subtle: false,
})
</script>

<template>
  <span :class="['badge', `tone-${tone}`, { 'is-subtle': subtle }]">
    <slot />
  </span>
</template>
