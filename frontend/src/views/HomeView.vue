<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/api/client'
import type { Conversation } from '@/types'

const router = useRouter()
const conversations = ref<Conversation[]>([])
const isLoading = ref(false)

onMounted(async () => {
  try {
    conversations.value = await api.conversations.list()
  } catch (error) {
    console.error('Failed to load conversations:', error)
  }
})

async function startNewConversation() {
  isLoading.value = true
  try {
    const conversation = await api.conversations.create('New Conversation')
    router.push(`/chat/${conversation.id}`)
  } catch (error) {
    console.error('Failed to create conversation:', error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen">
    <!-- Hero Section -->
    <header class="relative overflow-hidden">
      <!-- Background decorations -->
      <div class="absolute inset-0 overflow-hidden">
        <div
          class="absolute -top-40 -right-40 w-80 h-80 bg-primary-200/30 rounded-full blur-3xl"
        ></div>
        <div
          class="absolute top-20 -left-20 w-60 h-60 bg-eddie-light/50 rounded-full blur-3xl"
        ></div>
        <div
          class="absolute bottom-0 right-1/4 w-40 h-40 bg-blue-200/40 rounded-full blur-2xl"
        ></div>
      </div>

      <div class="relative max-w-4xl mx-auto px-6 pt-20 pb-16 text-center">
        <!-- Eddie mascot -->
        <div class="mb-8">
          <img
            src="/eddie.png"
            alt="Eddie"
            class="w-40 h-40 mx-auto rounded-full shadow-2xl shadow-eddie/30 animate-float object-cover"
          />
        </div>

        <h1
          class="text-5xl md:text-6xl font-bold bg-gradient-to-r from-slate-800 via-slate-700 to-primary-600 bg-clip-text text-transparent mb-6"
        >
          Adler Ducking
        </h1>

        <p class="text-xl text-slate-600 max-w-2xl mx-auto mb-10 leading-relaxed">
          Talk with Eddie, build your
          <span class="font-semibold text-primary-600">Adler Schema</span>, and discover your life
          direction through structured self-reflection.
        </p>

        <button @click="startNewConversation" :disabled="isLoading" class="btn-primary text-lg">
          <span v-if="isLoading" class="flex items-center gap-2">
            <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
                fill="none"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
              />
            </svg>
            Starting...
          </span>
          <span v-else class="flex items-center gap-2">
            Start Conversation
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 7l5 5m0 0l-5 5m5-5H6"
              />
            </svg>
          </span>
        </button>
      </div>
    </header>

    <!-- Recent Conversations -->
    <section v-if="conversations.length" class="max-w-4xl mx-auto px-6 py-12">
      <h2 class="text-2xl font-bold text-slate-800 mb-6">Recent Conversations</h2>
      <div class="grid gap-4">
        <router-link
          v-for="conv in conversations"
          :key="conv.id"
          :to="`/chat/${conv.id}`"
          class="card-hover p-5 flex items-center justify-between group"
        >
          <div class="flex items-center gap-4">
            <div
              class="w-12 h-12 rounded-xl bg-gradient-to-br from-primary-100 to-primary-200 flex items-center justify-center"
            >
              <svg class="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
            </div>
            <div>
              <div class="font-semibold text-slate-800 group-hover:text-primary-600 transition-colors">
                {{ conv.title }}
              </div>
              <div class="text-sm text-slate-500">
                {{ new Date(conv.created_at).toLocaleDateString('ja-JP') }}
              </div>
            </div>
          </div>
          <svg
            class="w-5 h-5 text-slate-400 group-hover:text-primary-500 group-hover:translate-x-1 transition-all"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </router-link>
      </div>
    </section>

    <!-- Features -->
    <section class="max-w-4xl mx-auto px-6 py-16">
      <h2 class="text-2xl font-bold text-slate-800 text-center mb-12">What is Adler Ducking?</h2>

      <div class="grid md:grid-cols-3 gap-6">
        <div class="card p-6 text-center group hover:shadow-xl transition-all duration-300">
          <div
            class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center group-hover:scale-110 transition-transform"
          >
            <span class="text-3xl">💬</span>
          </div>
          <h3 class="font-semibold text-lg text-slate-800 mb-2">Reflective Conversations</h3>
          <p class="text-slate-600 text-sm leading-relaxed">
            Talk with Eddie about your goals, beliefs, and life direction in a safe, judgment-free
            space.
          </p>
        </div>

        <div class="card p-6 text-center group hover:shadow-xl transition-all duration-300">
          <div
            class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-purple-100 to-purple-200 flex items-center justify-center group-hover:scale-110 transition-transform"
          >
            <span class="text-3xl">📊</span>
          </div>
          <h3 class="font-semibold text-lg text-slate-800 mb-2">Structured Schema</h3>
          <p class="text-slate-600 text-sm leading-relaxed">
            Build a personal model based on Adlerian psychology concepts, from your own words.
          </p>
        </div>

        <div class="card p-6 text-center group hover:shadow-xl transition-all duration-300">
          <div
            class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-amber-100 to-amber-200 flex items-center justify-center group-hover:scale-110 transition-transform"
          >
            <span class="text-3xl">🎯</span>
          </div>
          <h3 class="font-semibold text-lg text-slate-800 mb-2">Your Thinking, Visible</h3>
          <p class="text-slate-600 text-sm leading-relaxed">
            See patterns in your own words—not advice from others, but your authentic self.
          </p>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="text-center py-8 text-slate-500 text-sm">
      <p>Powered by Adler Schema</p>
    </footer>
  </div>
</template>
