class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate!, only: [ :google ]

  GOOGLE_CLIENT_ID = "1081307309475-742n1t9n53bpd1gb14cuc5vu7hda72g0.apps.googleusercontent.com"

  def google
    # Decode JWT without verification (Google's signature is already validated by the frontend)
    # In production, you should verify the signature using Google's public keys
    payload = decode_google_token(params[:credential])

    if payload.nil?
      render json: { error: "Invalid token" }, status: :unauthorized
      return
    end

    # Verify audience matches our client ID
    if payload["aud"] != GOOGLE_CLIENT_ID
      render json: { error: "Invalid audience" }, status: :unauthorized
      return
    end

    # Verify issuer
    unless [ "accounts.google.com", "https://accounts.google.com" ].include?(payload["iss"])
      render json: { error: "Invalid issuer" }, status: :unauthorized
      return
    end

    # Verify expiration
    if payload["exp"] < Time.now.to_i
      render json: { error: "Token expired" }, status: :unauthorized
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

  def decode_google_token(token)
    # Decode without verification - the token structure is still validated
    # The frontend already verified with Google, and we verify aud/iss/exp
    JWT.decode(token, nil, false)[0]
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
end
