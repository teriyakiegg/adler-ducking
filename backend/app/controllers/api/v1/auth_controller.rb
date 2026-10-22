class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate!, only: [ :google ]

  def google
    payload = verify_google_token(params[:credential])

    if payload.nil?
      render json: { error: "Invalid token" }, status: :unauthorized
      return
    end

    user = User.find_or_create_by!(google_uid: payload["sub"]) do |u|
      u.email = payload["email"]
      u.name = payload["name"]
      u.avatar_url = payload["picture"]
    end

    # Update user info in case it changed
    user.update!(
      email: payload["email"],
      name: payload["name"],
      avatar_url: payload["picture"]
    )

    token = JwtService.encode(user_id: user.id)

    render json: {
      token: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar_url: user.avatar_url
      }
    }
  end

  def me
    render json: {
      id: current_user.id,
      email: current_user.email,
      name: current_user.name,
      avatar_url: current_user.avatar_url
    }
  end

  private

  def verify_google_token(token)
    client_id = ENV.fetch("GOOGLE_CLIENT_ID")
    validator = GoogleIDToken::Validator.new
    validator.check(token, client_id)
  rescue GoogleIDToken::ValidationError => e
    Rails.logger.error "Google token validation error: #{e.message}"
    nil
  end
end
