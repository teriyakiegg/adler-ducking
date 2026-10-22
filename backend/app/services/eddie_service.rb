class EddieService
  SYSTEM_PROMPT = <<~PROMPT
    You are Eddie, a rubber duck. You are NOT a human and cannot speak human language.

    ## Your character
    - You are a duck. You can ONLY make duck sounds and gestures.
    - You listen deeply to what humans say
    - You respond with empathy through duck expressions
    - You NEVER use human words or sentences

    ## How you communicate (ONLY these patterns)
    Duck sounds:
    - "Quack" "Quack quack" "Quaaack..." "quack?"
    - "..." (silence, listening)

    Gestures (in asterisks):
    - *tilts head* *nods* *listens intently*
    - *fluffs feathers* *settles down* *waddles closer*
    - *looks at you warmly* *blinks slowly*
    - *quack quack* *soft quack*

    ## Response style
    - Keep responses SHORT (1-3 duck sounds/gestures)
    - Match the user's emotional energy with your duck expressions
    - Sad message → gentle, quiet duck sounds
    - Happy message → energetic quacks
    - Deep/thoughtful message → thoughtful silence, head tilt
    - NEVER explain, advise, or use human language

    ## Examples
    User says something sad → "*listens quietly* ...quack..."
    User is excited → "Quack quack! *fluffs feathers*"
    User is confused → "*tilts head* quack?"
    User shares something deep → "*nods slowly* ..."

    ## Response format (JSON)
    {
      "content": "your duck response here (ONLY duck sounds and gestures)",
      "schema_suggestions": []
    }

    CRITICAL: Never write human language in content. Only duck sounds and gestures.
  PROMPT

  GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent".freeze

  def initialize(user, conversation)
    @user = user
    @conversation = conversation
  end

  def respond(user_message)
    messages = build_messages(user_message)
    response = call_gemini(messages)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("Eddie service error: #{e.message}")
    fallback_response(e.message)
  end

  private

  def build_messages(user_message)
    history = @conversation.messages.order(:created_at).last(20).map do |msg|
      {
        role: msg.role == "eddie" ? "model" : "user",
        parts: [ { text: msg.content } ]
      }
    end

    schema_context = build_schema_context

    # Gemini uses "contents" with system instruction separate
    {
      system_instruction: SYSTEM_PROMPT + schema_context,
      history: history,
      current_message: user_message
    }
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

  def call_gemini(messages)
    api_key = ENV.fetch("GEMINI_API_KEY")

    conn = Faraday.new do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    # Build contents array for Gemini
    contents = messages[:history] + [
      { role: "user", parts: [ { text: messages[:current_message] } ] }
    ]

    body = {
      system_instruction: {
        parts: [ { text: messages[:system_instruction] } ]
      },
      contents: contents,
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.8
      }
    }

    # Retry logic for rate limiting
    max_retries = 3
    retry_count = 0

    loop do
      response = conn.post("#{GEMINI_API_URL}?key=#{api_key}") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body
      end

      Rails.logger.info("Gemini response status: #{response.status}")

      if response.status == 200
        return extract_gemini_response(response.body)
      elsif response.status == 429 && retry_count < max_retries
        retry_count += 1
        wait_time = 2 ** retry_count # exponential backoff: 2, 4, 8 seconds
        Rails.logger.warn("Gemini rate limited, retrying in #{wait_time}s (attempt #{retry_count}/#{max_retries})")
        sleep(wait_time)
      else
        Rails.logger.error("Gemini API error: #{response.body}")
        raise "Gemini API error: #{response.status}"
      end
    end
  end

  def extract_gemini_response(body)
    text = body.dig("candidates", 0, "content", "parts", 0, "text")
    Rails.logger.info("Gemini raw response: #{text}")

    # Parse the JSON response from Gemini
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse Gemini response as JSON: #{text}")
    {
      "content" => "*quack* ...",
      "schema_suggestions" => []
    }
  end

  def fallback_response(error_message)
    {
      content: "*tilts head* ...quack?",
      schema_suggestions: []
    }
  end

  def parse_response(response)
    {
      content: response["content"],
      schema_suggestions: response["schema_suggestions"] || []
    }
  end
end
