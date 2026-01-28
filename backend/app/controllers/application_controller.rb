class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    if token.nil?
      render json: { error: "Token required" }, status: :unauthorized
      return
    end

    decoded = JwtService.decode(token)
    if decoded.nil?
      render json: { error: "Invalid token" }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: decoded[:user_id])
    if @current_user.nil?
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
