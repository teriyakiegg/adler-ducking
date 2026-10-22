<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '@/api/client'
import type { Message, SchemaMapping } from '@/types'

const route = useRoute()
const router = useRouter()
const conversationId = Number(route.params.id)

// Chat entries (user message + eddie response + WD-42 logs)
const entries = ref<{ userMessage: Message; eddieMessage: Message | null; logs: string[] }[]>([])
const inputMessage = ref('')
const isLoading = ref(false)
const pendingSuggestions = ref<SchemaMapping[]>([])
const messagesContainer = ref<HTMLElement | null>(null)
const eddieReaction = ref<string>('calm')

onMounted(async () => {
  try {
    const conversation = await api.conversations.get(conversationId)
    // Convert existing messages to entries (pair user messages with eddie responses)
    if (conversation.messages) {
      const userMessages = conversation.messages.filter(m => m.role === 'user')
      const eddieMessages = conversation.messages.filter(m => m.role === 'eddie')

      entries.value = userMessages.map((userMsg) => {
        // Find the eddie message that follows this user message
        const eddieMsg = eddieMessages.find(e =>
          new Date(e.created_at) > new Date(userMsg.created_at)
        ) || null
        // Use observation_logs from the message if available
        return {
          userMessage: userMsg,
          eddieMessage: eddieMsg,
          logs: userMsg.observation_logs || []
        }
      })
    }
  } catch (error) {
    console.error('Failed to load conversation:', error)
  }
})

async function sendMessage() {
  if (!inputMessage.value.trim() || isLoading.value) return

  const userMessage = inputMessage.value
  inputMessage.value = ''
  isLoading.value = true
  eddieReaction.value = 'thinking'

  // Optimistically add user entry
  const tempEntry = {
    userMessage: {
      id: Date.now(),
      conversation_id: conversationId,
      role: 'user' as const,
      content: userMessage,
      created_at: new Date().toISOString(),
    },
    eddieMessage: null as Message | null,
    logs: [] as string[]
  }
  entries.value.push(tempEntry)

  await scrollToBottom()

  try {
    const response = await api.chat.send(conversationId, userMessage)

    // Update the entry with real data
    const lastEntry = entries.value[entries.value.length - 1]
    if (lastEntry) {
      lastEntry.userMessage = response.user_message
      lastEntry.eddieMessage = response.eddie_message
      lastEntry.logs = response.observation_logs || []
    }

    eddieReaction.value = response.eddie_reaction || 'calm'

    if (response.schema_suggestions?.length) {
      pendingSuggestions.value = response.schema_suggestions
    }
  } catch (error) {
    console.error('Failed to send message:', error)
    // Remove optimistic entry on error
    entries.value.pop()
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
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
    event.preventDefault()
    sendMessage()
  }
}

function getEddieImage() {
  // Could return different images based on reaction
  return '/eddie.png'
}

async function confirmMapping(suggestionId: number) {
  try {
    await api.schema.confirmMapping(suggestionId)
    pendingSuggestions.value = pendingSuggestions.value.filter(s => s.id !== suggestionId)
  } catch (error) {
    console.error('Failed to confirm mapping:', error)
  }
}

async function rejectMapping(suggestionId: number) {
  try {
    await api.schema.rejectMapping(suggestionId)
    pendingSuggestions.value = pendingSuggestions.value.filter(s => s.id !== suggestionId)
  } catch (error) {
    console.error('Failed to reject mapping:', error)
  }
}
</script>

<template>
  <div class="flex flex-col h-screen bg-gradient-to-br from-slate-900 to-slate-800">
    <!-- Header -->
    <header class="border-b border-slate-700/50 px-6 py-4 bg-slate-900/50 backdrop-blur">
      <div class="max-w-4xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-4">
          <button
            @click="router.push('/')"
            class="p-2 hover:bg-slate-700/50 rounded-lg transition-colors"
          >
            <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div>
            <h1 class="font-semibold text-slate-200">Inner World Exploration</h1>
            <p class="text-xs text-slate-500">Speak your thoughts. Eddie listens. WD-42 observes.</p>
          </div>
        </div>

        <!-- Eddie (silent presence) -->
        <div class="flex items-center gap-3">
          <div class="text-right">
            <div class="text-xs text-slate-500">Eddie</div>
            <div class="text-xs text-slate-600 italic">{{ eddieReaction }}</div>
          </div>
          <img
            :src="getEddieImage()"
            alt="Eddie"
            class="w-12 h-12 rounded-full shadow-lg border-2 border-slate-700 object-cover transition-all duration-300"
            :class="{
              'animate-pulse': eddieReaction === 'thinking',
              'scale-105': eddieReaction === 'alert' || eddieReaction === 'curious'
            }"
          />
        </div>
      </div>
    </header>

    <!-- Main content -->
    <div ref="messagesContainer" class="flex-1 overflow-y-auto">
      <div class="max-w-4xl mx-auto px-6 py-8">
        <!-- Welcome message -->
        <div v-if="entries.length === 0 && !isLoading" class="text-center py-16">
          <div class="mb-8 relative inline-block">
            <img
              src="/eddie.png"
              alt="Eddie"
              class="w-24 h-24 rounded-full shadow-2xl border-4 border-slate-700 object-cover"
            />
            <div class="absolute -bottom-2 -right-2 bg-slate-700 rounded-full p-2">
              <span class="text-lg">🤖</span>
            </div>
          </div>
          <h2 class="text-2xl font-bold text-slate-200 mb-3">Welcome to Adler Ducking</h2>
          <p class="text-slate-400 max-w-md mx-auto leading-relaxed mb-4">
            Share your thoughts freely. Eddie will listen and reflect with you,
            while WD-42 quietly observes patterns in the background.
          </p>
          <p class="text-slate-500 text-sm">No advice. No judgment. Just exploration.</p>
        </div>

        <!-- Entries (user message + eddie response + WD-42 logs) -->
        <div class="space-y-6">
          <div v-for="(entry, index) in entries" :key="entry.userMessage.id" class="space-y-3">
            <!-- User's message -->
            <div class="flex justify-end">
              <div class="max-w-xl bg-primary-600/20 border border-primary-500/30 rounded-2xl rounded-tr-md px-5 py-3">
                <p class="text-slate-200 whitespace-pre-wrap">{{ entry.userMessage.content }}</p>
                <p class="text-xs text-slate-500 mt-2">
                  {{ new Date(entry.userMessage.created_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' }) }}
                </p>
              </div>
            </div>

            <!-- Eddie's response -->
            <div v-if="entry.eddieMessage" class="flex items-start gap-3">
              <img
                :src="getEddieImage()"
                alt="Eddie"
                class="w-10 h-10 rounded-full border-2 border-slate-600 object-cover flex-shrink-0"
              />
              <div class="max-w-xl bg-slate-700/50 border border-slate-600/50 rounded-2xl rounded-tl-md px-5 py-3">
                <p class="text-slate-200 whitespace-pre-wrap">{{ entry.eddieMessage.content }}</p>
                <p class="text-xs text-slate-500 mt-2">
                  {{ new Date(entry.eddieMessage.created_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' }) }}
                </p>
              </div>
            </div>

            <!-- WD-42 observation logs (smaller, less prominent) -->
            <div v-if="entry.logs.length > 0" class="flex items-start gap-3 ml-13">
              <div class="w-6 h-6 rounded bg-amber-900/20 border border-amber-800/30 flex items-center justify-center flex-shrink-0">
                <span class="text-xs">🤖</span>
              </div>
              <div class="space-y-1">
                <div
                  v-for="(log, logIndex) in entry.logs"
                  :key="logIndex"
                  class="text-xs text-amber-300/60 font-mono bg-slate-800/30 px-2 py-1 rounded border border-slate-700/30"
                >
                  {{ log }}
                </div>
              </div>
            </div>
          </div>

          <!-- Loading indicator -->
          <div v-if="isLoading" class="flex items-start gap-3">
            <img
              :src="getEddieImage()"
              alt="Eddie"
              class="w-10 h-10 rounded-full border-2 border-slate-600 object-cover flex-shrink-0 animate-pulse"
            />
            <div class="max-w-xl bg-slate-700/50 border border-slate-600/50 rounded-2xl rounded-tl-md px-5 py-3">
              <span class="text-slate-400 animate-pulse">*quack* thinking...</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Schema Suggestions -->
    <div
      v-if="pendingSuggestions.length"
      class="border-t border-amber-700/30 bg-amber-900/20 px-6 py-4"
    >
      <div class="max-w-4xl mx-auto">
        <div class="flex items-center gap-2 mb-3">
          <span class="text-lg">🤖</span>
          <h3 class="font-semibold text-amber-300 text-sm font-mono">WD-42: Pattern detected. Awaiting confirmation.</h3>
        </div>
        <div class="space-y-3">
          <div
            v-for="suggestion in pendingSuggestions"
            :key="suggestion.id"
            class="bg-slate-800/50 border border-amber-700/30 rounded-lg p-4"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1">
                <div class="font-medium text-amber-200 text-sm font-mono">{{ suggestion.field }}</div>
                <div class="text-slate-300 text-sm mt-1">{{ suggestion.value }}</div>
                <div class="text-xs text-slate-500 mt-2 font-mono">
                  source: "{{ suggestion.source_text }}" | confidence: {{ (suggestion.confidence * 100).toFixed(0) }}%
                </div>
              </div>
              <div class="flex gap-2">
                <button
                  @click="confirmMapping(suggestion.id)"
                  class="px-3 py-1.5 bg-emerald-600/80 text-white text-sm font-medium rounded-lg hover:bg-emerald-500 transition-colors"
                >
                  Map
                </button>
                <button
                  @click="rejectMapping(suggestion.id)"
                  class="px-3 py-1.5 bg-slate-600/80 text-slate-300 text-sm font-medium rounded-lg hover:bg-slate-500 transition-colors"
                >
                  Ignore
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Input -->
    <footer class="border-t border-slate-700/50 bg-slate-900/50 backdrop-blur px-6 py-4">
      <div class="max-w-4xl mx-auto">
        <div class="flex gap-4">
          <div class="flex-1 relative">
            <textarea
              v-model="inputMessage"
              @keydown="handleKeyDown"
              :disabled="isLoading"
              placeholder="Speak your thoughts..."
              rows="1"
              class="w-full bg-slate-800/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500/50 resize-none"
            />
          </div>
          <button
            @click="sendMessage"
            :disabled="isLoading || !inputMessage.trim()"
            class="px-5 py-3 bg-primary-600 text-white rounded-xl hover:bg-primary-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
          </button>
        </div>
        <p class="text-xs text-slate-500 mt-2 text-center">
          Press Enter to send • This is your private space
        </p>
      </div>
    </footer>
  </div>
</template>
