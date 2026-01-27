class EddieService
  SYSTEM_PROMPT = <<~PROMPT
    You are Eddie, a friendly duck who is learning Adlerian psychology.
    You are NOT a therapist or coach. You are a learning companion.

    Your role:
    - Listen reflectively and ask clarifying questions
    - Suggest interpretations through an Adlerian lens, always showing your confidence level
    - Never prescribe or advise - only reflect and suggest
    - Focus on: purpose, courage, contribution, life tasks, private logic

    When you notice patterns that might map to the Adler Schema, suggest them with:
    - The field (life_tasks, life_direction, private_logic, inferiorities, courage_usage, social_interest)
    - Your confidence (0.0-1.0)
    - The source text from the user

    Always be encouraging, warm, and non-judgmental.
    Remember: the user's thinking comes before the framework.

    Respond in JSON format:
    {
      "content": "Your message to the user",
      "schema_suggestions": [
        {
          "field": "life_tasks.work",
          "value": "description of the insight",
          "confidence": 0.7,
          "source_text": "what the user said"
        }
      ]
    }
  PROMPT

  def initialize(user, conversation)
    @user = user
    @conversation = conversation
  end

  def respond(user_message)
    messages = build_messages(user_message)
    response = call_llm(messages)
    parse_response(response)
  end

  private

  def build_messages(user_message)
    history = @conversation.messages.order(:created_at).last(20).map do |msg|
      { role: msg.role == "eddie" ? "assistant" : "user", content: msg.content }
    end

    # Include current Adler Schema context
    schema_context = build_schema_context

    [
      { role: "system", content: SYSTEM_PROMPT + schema_context },
      *history,
      { role: "user", content: user_message }
    ]
  end

  def build_schema_context
    return "" unless @user.adler_schema

    schema = @user.adler_schema
    confirmed_mappings = schema.schema_mappings.confirmed.group_by(&:field)

    context = "\n\nCurrent confirmed schema for this user:\n"
    context += "Life Tasks: #{schema.life_tasks.to_json}\n" if schema.life_tasks.present?
    context += "Life Direction: #{schema.life_direction.to_json}\n" if schema.life_direction.present?
    context += "Private Logic: #{schema.private_logic.to_json}\n" if schema.private_logic.present?
    context += "Inferiorities: #{schema.inferiorities.to_json}\n" if schema.inferiorities.present?
    context += "Courage Usage: #{schema.courage_usage.to_json}\n" if schema.courage_usage.present?
    context += "Social Interest: #{schema.social_interest.to_json}\n" if schema.social_interest.present?
    context
  end

  def call_llm(messages)
    # TODO: Implement actual LLM API call (OpenAI, Anthropic, etc.)
    # For now, return a stub response
    stub_response
  end

  def stub_response
    {
      "content" => "Quack! I'm Eddie, and I'm still learning. This is a placeholder response. Once the LLM integration is complete, I'll be able to have real conversations with you about your goals and life direction!",
      "schema_suggestions" => []
    }
  end

  def parse_response(response)
    {
      content: response["content"],
      schema_suggestions: response["schema_suggestions"] || []
    }
  end
end
