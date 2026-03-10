<script setup lang="ts">
withDefaults(defineProps<{
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'md' | 'sm'
  block?: boolean
  type?: 'button' | 'submit' | 'reset'
  disabled?: boolean
}>(), {
  variant: 'primary',
  size: 'md',
  block: false,
  type: 'button',
  disabled: false,
})
</script>

<template>
  <button
    :type="type"
    :disabled="disabled"
    :class="[
      'btn',
      `btn-${variant}`,
      size !== 'md' ? `btn-${size}` : '',
      { 'btn-block': block },
    ]"
  >
    <slot />
  </button>
</template>
