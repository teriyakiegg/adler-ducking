class Api::V1::ChatController < ApplicationController
  before_action :set_conversation

  def create
    # Save user message
    user_message = @conversation.messages.create!(
      role: "user",
      content: params[:message]
    )

    # Get Eddie's response via LLM service
    eddie_response = EddieService.new(current_user, @conversation).respond(params[:message])

    # Save Eddie's response
    eddie_message = @conversation.messages.create!(
      role: "eddie",
      content: eddie_response[:content]
    )

    # Process schema mappings if suggested
    if eddie_response[:schema_suggestions].present?
      process_schema_suggestions(eddie_message, eddie_response[:schema_suggestions])
    end

    render json: {
      message: eddie_message,
      schema_suggestions: eddie_response[:schema_suggestions]
    }
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end

  def process_schema_suggestions(message, suggestions)
    adler_schema = current_user.adler_schema || current_user.create_adler_schema!

    suggestions.each do |suggestion|
      adler_schema.schema_mappings.create!(
        message: message,
        field: suggestion[:field],
        value: suggestion[:value],
        confidence: suggestion[:confidence],
        source_text: suggestion[:source_text],
        confirmed: false
      )
    end
  end
end
