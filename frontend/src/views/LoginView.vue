<script setup lang="ts">
import { useRouter } from 'vue-router'
import { GoogleLogin } from 'vue3-google-login'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

async function handleLoginSuccess(response: { credential: string }) {
  try {
    await auth.loginWithGoogle(response.credential)
    router.push('/')
  } catch (error) {
    console.error('Login failed:', error)
  }
}

function handleLoginError() {
  console.error('Google login failed')
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center">
    <!-- Background decorations -->
    <div class="absolute inset-0 overflow-hidden">
      <div class="absolute -top-40 -right-40 w-80 h-80 bg-primary-200/30 rounded-full blur-3xl"></div>
      <div class="absolute top-20 -left-20 w-60 h-60 bg-eddie-light/50 rounded-full blur-3xl"></div>
      <div class="absolute bottom-20 right-1/4 w-40 h-40 bg-blue-200/40 rounded-full blur-2xl"></div>
    </div>

    <div class="relative card p-10 max-w-md w-full mx-4">
      <div class="text-center mb-8">
        <div
          class="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-eddie-light to-eddie rounded-full shadow-xl shadow-eddie/30 mb-6 animate-float"
        >
          <span class="text-4xl">🦆</span>
        </div>
        <h1 class="text-3xl font-bold text-slate-800 mb-2">Adler Ducking</h1>
        <p class="text-slate-600">Sign in to start your journey with Eddie</p>
      </div>

      <div class="flex justify-center">
        <GoogleLogin :callback="handleLoginSuccess" :error="handleLoginError" />
      </div>

      <p class="text-center text-sm text-slate-500 mt-8">
        By signing in, you agree to talk with a duck about your life goals.
      </p>
    </div>
  </div>
</template>
