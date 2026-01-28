import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { api } from '@/api/client'

interface User {
  id: number
  email: string
  name: string
  avatar_url: string | null
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('auth_token'))

  const isLoggedIn = computed(() => !!token.value)

  async function loginWithGoogle(credential: string) {
    const response = await api.auth.googleLogin(credential)
    token.value = response.token
    user.value = response.user
    localStorage.setItem('auth_token', response.token)
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('auth_token')
  }

  async function fetchCurrentUser() {
    if (!token.value) return
    try {
      user.value = await api.auth.me()
    } catch {
      logout()
    }
  }

  return { user, token, isLoggedIn, loginWithGoogle, logout, fetchCurrentUser }
})
