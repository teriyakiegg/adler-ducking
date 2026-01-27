<script setup lang="ts">
import type { Message } from '@/types'

defineProps<{
  message: Message
}>()
</script>

<template>
  <div class="message" :class="message.role">
    <div class="avatar">
      <span v-if="message.role === 'eddie'">🦆</span>
      <span v-else>👤</span>
    </div>
    <div class="content">
      <div class="role">{{ message.role === 'eddie' ? 'Eddie' : 'You' }}</div>
      <div class="text">{{ message.content }}</div>
    </div>
  </div>
</template>

<style scoped>
.message {
  display: flex;
  gap: 12px;
  padding: 16px;
  border-radius: 12px;
  margin-bottom: 12px;
}

.message.eddie {
  background: #f0f7ff;
}

.message.user {
  background: #f5f5f5;
}

.avatar {
  font-size: 24px;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.content {
  flex: 1;
}

.role {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 4px;
  color: #666;
}

.text {
  line-height: 1.5;
  white-space: pre-wrap;
}
</style>
