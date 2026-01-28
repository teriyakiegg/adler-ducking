<script setup lang="ts">
import type { Message } from '@/types'

defineProps<{
  message: Message
}>()
</script>

<template>
  <div class="flex items-start gap-4" :class="message.role === 'user' ? 'flex-row-reverse' : ''">
    <!-- Avatar -->
    <div
      v-if="message.role === 'eddie'"
      class="w-10 h-10 bg-gradient-to-br from-eddie-light to-eddie rounded-full flex items-center justify-center flex-shrink-0 shadow-lg shadow-eddie/20"
    >
      <span class="text-xl">🦆</span>
    </div>
    <div
      v-else
      class="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center flex-shrink-0 shadow-lg shadow-primary-500/20"
    >
      <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        />
      </svg>
    </div>

    <!-- Message bubble -->
    <div
      class="max-w-[75%] rounded-2xl px-5 py-3 shadow-sm"
      :class="
        message.role === 'eddie'
          ? 'bg-white border border-slate-100'
          : 'bg-gradient-to-br from-primary-500 to-primary-600 text-white'
      "
    >
      <div class="text-sm font-medium mb-1" :class="message.role === 'eddie' ? 'text-eddie-dark' : 'text-white/80'">
        {{ message.role === 'eddie' ? 'Eddie' : 'You' }}
      </div>
      <div class="leading-relaxed whitespace-pre-wrap" :class="message.role === 'eddie' ? 'text-slate-700' : ''">
        {{ message.content }}
      </div>
    </div>
  </div>
</template>
