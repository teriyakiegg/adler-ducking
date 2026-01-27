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
  <div class="home">
    <header class="hero">
      <div class="logo">🦆</div>
      <h1>Adler Ducking</h1>
      <p class="tagline">
        Talk with Eddie, build your Adler Schema, and discover your life direction.
      </p>
      <button @click="startNewConversation" :disabled="isLoading" class="cta">
        {{ isLoading ? 'Starting...' : 'Start Conversation' }}
      </button>
    </header>

    <section v-if="conversations.length" class="conversations">
      <h2>Recent Conversations</h2>
      <ul>
        <li v-for="conv in conversations" :key="conv.id">
          <router-link :to="`/chat/${conv.id}`">
            <span class="title">{{ conv.title }}</span>
            <span class="date">{{ new Date(conv.created_at).toLocaleDateString() }}</span>
          </router-link>
        </li>
      </ul>
    </section>

    <section class="about">
      <h2>What is Adler Ducking?</h2>
      <div class="features">
        <div class="feature">
          <span class="icon">💬</span>
          <h3>Reflective Conversations</h3>
          <p>Talk with Eddie about your goals, beliefs, and life direction.</p>
        </div>
        <div class="feature">
          <span class="icon">📊</span>
          <h3>Structured Schema</h3>
          <p>Build a personal model based on Adlerian psychology concepts.</p>
        </div>
        <div class="feature">
          <span class="icon">🎯</span>
          <h3>Your Thinking, Visible</h3>
          <p>See patterns in your own words, not advice from others.</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home {
  max-width: 800px;
  margin: 0 auto;
  padding: 40px 20px;
}

.hero {
  text-align: center;
  padding: 60px 0;
}

.logo {
  font-size: 80px;
  margin-bottom: 16px;
}

h1 {
  font-size: 36px;
  margin: 0 0 12px;
}

.tagline {
  font-size: 18px;
  color: #666;
  margin-bottom: 32px;
}

.cta {
  padding: 16px 32px;
  font-size: 18px;
  font-weight: 600;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.2s;
}

.cta:hover {
  background: #2563eb;
}

.cta:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.conversations {
  margin-top: 48px;
}

.conversations h2 {
  font-size: 20px;
  margin-bottom: 16px;
}

.conversations ul {
  list-style: none;
  padding: 0;
}

.conversations li a {
  display: flex;
  justify-content: space-between;
  padding: 16px;
  background: #f5f5f5;
  border-radius: 8px;
  margin-bottom: 8px;
  text-decoration: none;
  color: inherit;
  transition: background 0.2s;
}

.conversations li a:hover {
  background: #eee;
}

.conversations .title {
  font-weight: 500;
}

.conversations .date {
  color: #666;
  font-size: 14px;
}

.about {
  margin-top: 64px;
}

.about h2 {
  text-align: center;
  font-size: 24px;
  margin-bottom: 32px;
}

.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 24px;
}

.feature {
  text-align: center;
  padding: 24px;
  background: #f9fafb;
  border-radius: 12px;
}

.feature .icon {
  font-size: 40px;
}

.feature h3 {
  font-size: 16px;
  margin: 12px 0 8px;
}

.feature p {
  font-size: 14px;
  color: #666;
  margin: 0;
}
</style>
