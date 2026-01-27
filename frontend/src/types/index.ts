export interface User {
  id: number
  email: string
  name: string
}

export interface Message {
  id: number
  conversation_id: number
  role: 'user' | 'eddie' | 'system'
  content: string
  created_at: string
}

export interface Conversation {
  id: number
  title: string
  summary: string | null
  messages?: Message[]
  created_at: string
}

export interface SchemaMapping {
  id: number
  field: string
  value: string
  confidence: number
  confirmed: boolean
  source_text: string
}

export interface AdlerSchema {
  id: number
  life_tasks: Record<string, unknown>
  life_direction: Record<string, unknown>
  private_logic: Record<string, unknown>
  inferiorities: Record<string, unknown>
  courage_usage: Record<string, unknown>
  social_interest: Record<string, unknown>
  schema_mappings?: SchemaMapping[]
}

export interface ChatResponse {
  message: Message
  schema_suggestions: SchemaMapping[]
}
