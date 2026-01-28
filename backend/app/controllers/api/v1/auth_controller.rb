class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate!, only: [ :google ]

  GOOGLE_CLIENT_ID = "1081307309475-742n1t9n53bpd1gb14cuc5vu7hda72g0.apps.googleusercontent.com"

  def google
    validator = GoogleIDToken::Validator.new
    payload = validator.check(params[:credential], GOOGLE_CLIENT_ID)

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
  rescue GoogleIDToken::ValidationError => e
    render json: { error: e.message }, status: :unauthorized
  end

  def me
    render json: {
      id: current_user.id,
      email: current_user.email,
      name: current_user.name,
      avatar_url: current_user.avatar_url
    }
  end
end
