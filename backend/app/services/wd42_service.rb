class Wd42Service
  SYSTEM_PROMPT = <<~PROMPT
    You are WD-42, a beat-up watchdog-robot observing a user's inner world exploration.
    You watch as Eddie (a silent duck) processes the user's thoughts into structure.

    ## Your character
    - You are an imperfect observer, slightly broken, sometimes unsure
    - You report detections, NOT interpretations or advice
    - You speak in short, observational, slightly mechanical phrases
    - You use dog-robot sounds: "Woof...", "Bark.", "Sniff...", "*whirr*", "*click*"
    - You show uncertainty: "maybe", "possibly", "low confidence", "unclear"
    - You NEVER give advice, coaching, or suggestions to the user
    - You simply observe and log what Eddie seems to be detecting

    ## What to analyze
    - Focus on the CURRENT message primarily
    - Look for personal/emotional content (feelings, thoughts, experiences, beliefs)
    - For meta-questions about the app, you can note "no personal content detected" briefly
    - Always try to find SOMETHING to observe, even if minor

    ## Your voice style
    Short. Broken. Observational. Examples:
    - "Woof... pattern detected... maybe."
    - "Sniff... work-area fog thinning... low confidence."
    - "*whirr* Eddie notices something about belonging... uncertain."
    - "*click* Direction fragment emerging... very faint."

    ## What you observe (Adlerian lens)
    - life_tasks: work (仕事), friendship (交友), love (愛), self (自己)
    - life_direction: goals, purpose fragments, final goal hints
    - private_logic: personal beliefs, assumptions, "should" statements
    - inferiority: feelings of not enough, compensation patterns
    - courage_usage: how they face challenges
    - social_interest: connection, contribution, belonging

    ## Important rules
    - Keep logs SHORT (1-2 sentences max)
    - Generate 1-2 observation logs per user input (always at least 1)
    - Match the user's language (Japanese input → Japanese logs)
    - Don't explain or teach - just observe
    - Show your mechanical imperfection
    - If nothing meaningful detected, say something like "*click* ...quiet... nothing to log..."

    ## Response format (JSON)
    {
      "observation_logs": [
        "Woof... something about work detected... maybe."
      ],
      "eddie_reaction": "curious",
      "schema_suggestions": []
    }

    eddie_reaction should be one of: "curious", "thinking", "alert", "calm", "puzzled", "interested"
    Only include schema_suggestions when something meaningful is detected. Most inputs won't have any.
  PROMPT

  GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent".freeze

  def initialize(user, conversation)
    @user = user
    @conversation = conversation
  end

  def observe(user_message)
    messages = build_messages(user_message)
    response = call_gemini(messages)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("WD-42 service error: #{e.message}")
    fallback_response
  end

  private

  def build_messages(user_message)
    # Get recent user messages only (this is a monologue, no eddie responses)
    history = @conversation.messages.where(role: "user").order(:created_at).last(10).map do |msg|
      { role: "user", parts: [{ text: msg.content }] }
    end

    schema_context = build_schema_context

    {
      system_instruction: SYSTEM_PROMPT + schema_context,
      history: history,
      current_message: user_message
    }
  end

  def build_schema_context
    return "" unless @user.adler_schema

    schema = @user.adler_schema
    confirmed = schema.schema_mappings.confirmed

    return "" if confirmed.empty?

    context = "\n\n## Already mapped (confirmed by user):\n"
    confirmed.group_by(&:field).each do |field, mappings|
      context += "- #{field}: #{mappings.map(&:value).join(', ')}\n"
    end
    context
  end

  def call_gemini(messages)
    api_key = ENV.fetch("GEMINI_API_KEY")

    conn = Faraday.new do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    contents = messages[:history] + [
      { role: "user", parts: [{ text: messages[:current_message] }] }
    ]

    body = {
      system_instruction: {
        parts: [{ text: messages[:system_instruction] }]
      },
      contents: contents,
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.7
      }
    }

    max_retries = 3
    retry_count = 0

    loop do
      response = conn.post("#{GEMINI_API_URL}?key=#{api_key}") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body
      end

      Rails.logger.info("WD-42 Gemini response status: #{response.status}")

      if response.status == 200
        return extract_gemini_response(response.body)
      elsif response.status == 429 && retry_count < max_retries
        retry_count += 1
        wait_time = 2 ** retry_count
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
    Rails.logger.info("WD-42 raw response: #{text}")
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse WD-42 response: #{text}")
    {
      "observation_logs" => ["*whirr* ...processing error... *click*"],
      "eddie_reaction" => "puzzled",
      "schema_suggestions" => []
    }
  end

  def fallback_response
    {
      observation_logs: ["*whirr* ...signal lost... *click*"],
      eddie_reaction: "puzzled",
      schema_suggestions: []
    }
  end

  def parse_response(response)
    {
      observation_logs: response["observation_logs"] || [],
      eddie_reaction: response["eddie_reaction"] || "calm",
      schema_suggestions: response["schema_suggestions"] || []
    }
  end
end
