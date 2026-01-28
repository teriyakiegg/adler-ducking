import type { Conversation, ChatResponse, AdlerSchema } from '@/types'

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1'

function getAuthToken(): string | null {
  return localStorage.getItem('auth_token')
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken()

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  if (response.status === 401) {
    localStorage.removeItem('auth_token')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`)
  }

  return response.json()
}

export const api = {
  auth: {
    googleLogin: (credential: string) =>
      request<{ token: string; user: { id: number; email: string; name: string; avatar_url: string | null } }>(
        '/auth/google',
        {
          method: 'POST',
          body: JSON.stringify({ credential }),
        }
      ),

    me: () =>
      request<{ id: number; email: string; name: string; avatar_url: string | null }>('/auth/me'),
  },

  conversations: {
    list: () => request<Conversation[]>('/conversations'),

    get: (id: number) => request<Conversation>(`/conversations/${id}`),

    create: (title: string) =>
      request<Conversation>('/conversations', {
        method: 'POST',
        body: JSON.stringify({ conversation: { title } }),
      }),
  },

  chat: {
    send: (conversationId: number, message: string) =>
      request<ChatResponse>(`/conversations/${conversationId}/chat`, {
        method: 'POST',
        body: JSON.stringify({ message }),
      }),
  },

  schema: {
    get: () => request<AdlerSchema>('/adler_schema'),

    confirmMapping: (id: number) =>
      request<void>(`/schema_mappings/${id}/confirm`, { method: 'POST' }),

    rejectMapping: (id: number) =>
      request<void>(`/schema_mappings/${id}/reject`, { method: 'POST' }),
  },
}
