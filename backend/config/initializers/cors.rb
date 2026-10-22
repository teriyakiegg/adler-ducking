# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development origins
    origins_list = [ "localhost:5173", "127.0.0.1:5173" ]

    # Production (Vercel) - only allow specific URL, no wildcards
    if ENV["FRONTEND_URL"].present?
      origins_list << ENV["FRONTEND_URL"].gsub(%r{^https?://}, "")
    end

    # Additional allowed origins (comma-separated) for preview deployments
    # Set ALLOWED_ORIGINS env var with specific preview URLs when needed
    if ENV["ALLOWED_ORIGINS"].present?
      ENV["ALLOWED_ORIGINS"].split(",").each do |origin|
        origins_list << origin.strip.gsub(%r{^https?://}, "")
      end
    end

    origins(*origins_list)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      max_age: 86400
  end
end
