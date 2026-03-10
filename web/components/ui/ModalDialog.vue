<script setup lang="ts">
defineProps<{
  open: boolean
  title: string
}>()

defineEmits<{
  close: []
}>()
</script>

<template>
  <Teleport to="body">
    <Transition name="fade-up">
      <div v-if="open" class="modal-backdrop" @click="$emit('close')">
        <div class="modal-card" @click.stop>
          <div class="modal-head">
            <h3>{{ title }}</h3>
            <button type="button" class="icon-btn" aria-label="关闭" @click="$emit('close')">x</button>
          </div>
          <div class="modal-body">
            <slot />
          </div>
          <div v-if="$slots.footer" class="modal-foot">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
