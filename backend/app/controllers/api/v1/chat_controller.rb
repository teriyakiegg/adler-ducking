class Api::V1::ChatController < ApplicationController
  before_action :set_conversation

  def create
    # Save user message
    user_message = @conversation.messages.create!(
      role: "user",
      content: params[:message]
    )

    # Eddie responds conversationally
    eddie_response = EddieService.new(current_user, @conversation).respond(params[:message])
    eddie_message = @conversation.messages.create!(
      role: "eddie",
      content: eddie_response[:content]
    )

    # WD-42 observes in the background
    wd42_response = Wd42Service.new(current_user, @conversation).observe(params[:message])

    # Save observation logs to user message
    user_message.update!(observation_logs: wd42_response[:observation_logs] || [])

    # Process schema mappings from both services and get saved records with IDs
    all_suggestions = (eddie_response[:schema_suggestions] || []) + (wd42_response[:schema_suggestions] || [])
    saved_mappings = []
    if all_suggestions.present?
      saved_mappings = process_schema_suggestions(user_message, all_suggestions)
    end

    # Auto-generate title after first message only
    if @conversation.title == "New Conversation" && @conversation.messages.where(role: "user").count == 1
      Rails.logger.info "Generating title for conversation #{@conversation.id}"
      generate_conversation_title_from_history
    end

    render json: {
      user_message: user_message,
      eddie_message: eddie_message,
      observation_logs: wd42_response[:observation_logs],
      eddie_reaction: wd42_response[:eddie_reaction],
      schema_suggestions: saved_mappings,
      conversation_title: @conversation.title
    }
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end

  def generate_conversation_title_from_history
    recent_messages = @conversation.messages.where(role: "user").order(:created_at).limit(5)
    conversation_text = recent_messages.map(&:content).join("\n")

    prompt = <<~PROMPT
      Generate a very short title (3-5 words max, in the same language as the text) summarizing what this person is exploring:

      #{conversation_text.truncate(500)}

      Reply with ONLY the title, no quotes, no explanation.
    PROMPT

    begin
      response = Faraday.post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{ENV['GEMINI_API_KEY']}") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = { contents: [{ parts: [{ text: prompt }] }] }.to_json
      end

      if response.success?
        result = JSON.parse(response.body)
        title = result.dig("candidates", 0, "content", "parts", 0, "text")&.strip
        @conversation.update!(title: title.truncate(255)) if title.present?
      end
    rescue => e
      Rails.logger.error "Failed to generate conversation title: #{e.message}"
      first_user_message = @conversation.messages.where(role: "user").order(:created_at).first
      @conversation.update!(title: first_user_message&.content&.truncate(50) || "Exploration")
    end
  end

  def process_schema_suggestions(message, suggestions)
    adler_schema = current_user.adler_schema || current_user.create_adler_schema!

    suggestions.map do |suggestion|
      adler_schema.schema_mappings.create!(
        message: message,
        field: suggestion["field"] || suggestion[:field],
        value: suggestion["value"] || suggestion[:value],
        confidence: suggestion["confidence"] || suggestion[:confidence],
        source_text: suggestion["source_text"] || suggestion[:source_text],
        confirmed: false
      )
    end
  end
end
