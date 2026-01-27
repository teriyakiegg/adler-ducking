class Api::V1::ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show ]

  def index
    @conversations = current_user.conversations.order(created_at: :desc)
    render json: @conversations
  end

  def show
    render json: @conversation, include: :messages
  end

  def create
    @conversation = current_user.conversations.build(conversation_params)
    if @conversation.save
      render json: @conversation, status: :created
    else
      render json: { errors: @conversation.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:title)
  end
end
