import type { Conversation, ChatResponse, AdlerSchema } from '@/types'

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1'

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  })

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`)
  }

  return response.json()
}

export const api = {
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
