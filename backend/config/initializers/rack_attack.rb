# frozen_string_literal: true

class Rack::Attack
  # Throttle all requests by IP (60 requests per minute)
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts by IP (5 requests per minute)
  throttle("auth/ip", limit: 5, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/google" && req.post?
      req.ip
    end
  end

  # Throttle chat API by IP (30 requests per minute - expensive Gemini API calls)
  throttle("chat/ip", limit: 30, period: 1.minute) do |req|
    if req.path.include?("/chat") && req.post?
      req.ip
    end
  end

  # Throttle conversation creation (10 per minute)
  throttle("conversations/ip", limit: 10, period: 1.minute) do |req|
    if req.path == "/api/v1/conversations" && req.post?
      req.ip
    end
  end

  # Block suspicious requests
  blocklist("block/bad-requests") do |req|
    # Block requests with SQL injection patterns
    req.query_string.to_s.match?(/(\%27)|(\')|(\-\-)|(\%23)|(#)/i) ||
      req.path.match?(/(\%27)|(\')|(\-\-)|(\%23)|(#)/i)
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Rate limit exceeded. Retry after #{retry_after} seconds" }.to_json ]
    ]
  end
end
