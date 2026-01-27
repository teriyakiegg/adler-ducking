<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/api/client'
import ChatMessage from '@/components/ChatMessage.vue'
import type { Message, SchemaMapping } from '@/types'

const route = useRoute()
const conversationId = Number(route.params.id)

const messages = ref<Message[]>([])
const inputMessage = ref('')
const isLoading = ref(false)
const pendingSuggestions = ref<SchemaMapping[]>([])
const messagesContainer = ref<HTMLElement | null>(null)

onMounted(async () => {
  const conversation = await api.conversations.get(conversationId)
  messages.value = conversation.messages || []
})

async function sendMessage() {
  if (!inputMessage.value.trim() || isLoading.value) return

  const userMessage = inputMessage.value
  inputMessage.value = ''
  isLoading.value = true

  // Optimistically add user message
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
  <div class="chat-view">
    <header class="chat-header">
      <h1>🦆 Chat with Eddie</h1>
    </header>

    <div ref="messagesContainer" class="messages">
      <div v-if="messages.length === 0" class="welcome">
        <div class="eddie-intro">
          <span class="duck">🦆</span>
          <h2>Hi! I'm Eddie</h2>
          <p>
            I'm a duck learning Adlerian psychology. I'm here to listen and help you explore your
            thoughts about goals, beliefs, and life direction.
          </p>
          <p>What's on your mind today?</p>
        </div>
      </div>

      <ChatMessage v-for="msg in messages" :key="msg.id" :message="msg" />

      <div v-if="isLoading" class="loading">
        <span class="duck">🦆</span>
        <span class="dots">...</span>
      </div>
    </div>

    <div v-if="pendingSuggestions.length" class="suggestions">
      <h3>Eddie noticed something:</h3>
      <div v-for="suggestion in pendingSuggestions" :key="suggestion.id" class="suggestion">
        <p>
          <strong>{{ suggestion.field }}</strong
          >: {{ suggestion.value }}
        </p>
        <p class="confidence">Confidence: {{ (suggestion.confidence * 100).toFixed(0) }}%</p>
        <div class="actions">
          <button @click="api.schema.confirmMapping(suggestion.id)">Accept</button>
          <button @click="api.schema.rejectMapping(suggestion.id)">Reject</button>
        </div>
      </div>
    </div>

    <footer class="chat-input">
      <textarea
        v-model="inputMessage"
        placeholder="Type your message..."
        @keydown="handleKeyDown"
        :disabled="isLoading"
      />
      <button @click="sendMessage" :disabled="isLoading || !inputMessage.trim()">Send</button>
    </footer>
  </div>
</template>

<style scoped>
.chat-view {
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-width: 800px;
  margin: 0 auto;
}

.chat-header {
  padding: 16px;
  border-bottom: 1px solid #eee;
}

.chat-header h1 {
  margin: 0;
  font-size: 20px;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.welcome {
  text-align: center;
  padding: 40px 20px;
}

.eddie-intro .duck {
  font-size: 64px;
}

.eddie-intro h2 {
  margin: 16px 0 8px;
}

.eddie-intro p {
  color: #666;
  max-width: 400px;
  margin: 8px auto;
}

.loading {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px;
  color: #666;
}

.loading .duck {
  font-size: 24px;
}

.loading .dots {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.3;
  }
  50% {
    opacity: 1;
  }
}

.suggestions {
  padding: 16px;
  background: #fffbeb;
  border-top: 1px solid #fde68a;
}

.suggestion {
  padding: 12px;
  background: white;
  border-radius: 8px;
  margin-bottom: 8px;
}

.confidence {
  font-size: 12px;
  color: #666;
}

.actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.actions button {
  padding: 4px 12px;
  border-radius: 4px;
  border: 1px solid #ddd;
  cursor: pointer;
}

.actions button:first-child {
  background: #10b981;
  color: white;
  border-color: #10b981;
}

.chat-input {
  display: flex;
  gap: 12px;
  padding: 16px;
  border-top: 1px solid #eee;
}

.chat-input textarea {
  flex: 1;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  resize: none;
  font-family: inherit;
  font-size: 14px;
}

.chat-input button {
  padding: 12px 24px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
}

.chat-input button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
