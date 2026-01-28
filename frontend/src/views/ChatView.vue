<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '@/api/client'
import ChatMessage from '@/components/ChatMessage.vue'
import type { Message, SchemaMapping } from '@/types'

const route = useRoute()
const router = useRouter()
const conversationId = Number(route.params.id)

const messages = ref<Message[]>([])
const inputMessage = ref('')
const isLoading = ref(false)
const pendingSuggestions = ref<SchemaMapping[]>([])
const messagesContainer = ref<HTMLElement | null>(null)

onMounted(async () => {
  try {
    const conversation = await api.conversations.get(conversationId)
    messages.value = conversation.messages || []
  } catch (error) {
    console.error('Failed to load conversation:', error)
  }
})

async function sendMessage() {
  if (!inputMessage.value.trim() || isLoading.value) return

  const userMessage = inputMessage.value
  inputMessage.value = ''
  isLoading.value = true

  messages.value.push({
    id: Date.now(),
    conversation_id: conversationId,
    role: 'user',
    content: userMessage,
    created_at: new Date().toISOString(),
  })

  await scrollToBottom()

  try {
    const response = await api.chat.send(conversationId, userMessage)
    messages.value.push(response.message)

    if (response.schema_suggestions?.length) {
      pendingSuggestions.value = response.schema_suggestions
    }
  } catch (error) {
    console.error('Failed to send message:', error)
  } finally {
    isLoading.value = false
    await scrollToBottom()
  }
}

async function scrollToBottom() {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

function handleKeyDown(event: KeyboardEvent) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    sendMessage()
  }
}
</script>

<template>
  <div class="flex flex-col h-screen bg-gradient-to-br from-slate-50 to-blue-50">
    <!-- Header -->
    <header class="glass border-b border-slate-200/50 px-6 py-4">
      <div class="max-w-3xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-4">
          <button
            @click="router.push('/')"
            class="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <svg class="w-5 h-5 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </button>
          <div class="flex items-center gap-3">
            <div
              class="w-10 h-10 bg-gradient-to-br from-eddie-light to-eddie rounded-full flex items-center justify-center shadow-lg shadow-eddie/20"
            >
              <span class="text-xl">🦆</span>
            </div>
            <div>
              <h1 class="font-semibold text-slate-800">Chat with Eddie</h1>
              <p class="text-xs text-slate-500">Your Adlerian thinking duck</p>
            </div>
          </div>
        </div>
      </div>
    </header>

    <!-- Messages -->
    <div ref="messagesContainer" class="flex-1 overflow-y-auto">
      <div class="max-w-3xl mx-auto px-6 py-8">
        <!-- Welcome message -->
        <div v-if="messages.length === 0" class="text-center py-16">
          <div
            class="inline-flex items-center justify-center w-24 h-24 bg-gradient-to-br from-eddie-light to-eddie rounded-full shadow-2xl shadow-eddie/30 mb-6 animate-float"
          >
            <span class="text-5xl">🦆</span>
          </div>
          <h2 class="text-2xl font-bold text-slate-800 mb-3">Hi! I'm Eddie</h2>
          <p class="text-slate-600 max-w-md mx-auto leading-relaxed">
            I'm a duck learning Adlerian psychology. I'm here to listen and help you explore your
            thoughts about goals, beliefs, and life direction.
          </p>
          <p class="text-slate-500 mt-4">What's on your mind today?</p>
        </div>

        <!-- Message list -->
        <div class="space-y-4">
          <ChatMessage v-for="msg in messages" :key="msg.id" :message="msg" />

          <!-- Typing indicator -->
          <div v-if="isLoading" class="flex items-start gap-4">
            <div
              class="w-10 h-10 bg-gradient-to-br from-eddie-light to-eddie rounded-full flex items-center justify-center flex-shrink-0 shadow-lg shadow-eddie/20"
            >
              <span class="text-xl">🦆</span>
            </div>
            <div class="card px-5 py-4">
              <div class="flex gap-1">
                <span class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 0ms"></span>
                <span class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 150ms"></span>
                <span class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 300ms"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Schema Suggestions -->
    <div
      v-if="pendingSuggestions.length"
      class="border-t border-amber-200 bg-gradient-to-r from-amber-50 to-orange-50 px-6 py-4"
    >
      <div class="max-w-3xl mx-auto">
        <div class="flex items-center gap-2 mb-3">
          <span class="text-lg">💡</span>
          <h3 class="font-semibold text-amber-800">Eddie noticed something</h3>
        </div>
        <div class="space-y-3">
          <div
            v-for="suggestion in pendingSuggestions"
            :key="suggestion.id"
            class="card p-4 border-amber-200"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1">
                <div class="font-medium text-slate-800">{{ suggestion.field }}</div>
                <div class="text-slate-600 text-sm mt-1">{{ suggestion.value }}</div>
                <div class="text-xs text-slate-400 mt-2">
                  Confidence: {{ (suggestion.confidence * 100).toFixed(0) }}%
                </div>
              </div>
              <div class="flex gap-2">
                <button
                  @click="api.schema.confirmMapping(suggestion.id)"
                  class="px-3 py-1.5 bg-emerald-500 text-white text-sm font-medium rounded-lg hover:bg-emerald-600 transition-colors"
                >
                  Accept
                </button>
                <button
                  @click="api.schema.rejectMapping(suggestion.id)"
                  class="px-3 py-1.5 bg-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-300 transition-colors"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Input -->
    <footer class="glass border-t border-slate-200/50 px-6 py-4">
      <div class="max-w-3xl mx-auto">
        <div class="flex gap-4">
          <div class="flex-1 relative">
            <textarea
              v-model="inputMessage"
              @keydown="handleKeyDown"
              :disabled="isLoading"
              placeholder="Type your message..."
              rows="1"
              class="input resize-none pr-12"
            />
          </div>
          <button
            @click="sendMessage"
            :disabled="isLoading || !inputMessage.trim()"
            class="btn-primary px-5"
          >
            <svg
              class="w-5 h-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
              />
            </svg>
          </button>
        </div>
        <p class="text-xs text-slate-400 mt-2 text-center">
          Press Enter to send, Shift+Enter for new line
        </p>
      </div>
    </footer>
  </div>
</template>
