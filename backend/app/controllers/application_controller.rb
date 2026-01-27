class ApplicationController < ActionController::API
  private

  # TODO: Replace with actual authentication (devise-jwt)
  def current_user
    @current_user ||= User.first_or_create!(
      email: "dev@example.com",
      name: "Dev User"
    )
  end
end
