# frozen_string_literal: true

# Rack::Attack configuration for rate limiting and blocking abusive requests
# https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache for storing rate limit data
  # In production with Solid Cache, this will use the database-backed cache
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new if defined?(Redis)
  Rack::Attack.cache.store ||= Rails.cache

  ### Throttle Spammy Clients ###
  # If any single client IP is making tons of requests, block them
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/packs", "/cable")
  end

  ### Prevent Brute-Force Login Attacks ###
  # Throttle POST requests to /users/sign_in by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email parameter
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize the email to prevent different variations
      req.params.dig("user", "email")&.to_s&.downcase&.gsub(/\s+/, "")
    end
  end

  ### Prevent Brute-Force Password Reset ###
  throttle("password_reset/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  ### Prevent Account Creation Abuse ###
  throttle("registrations/ip", limit: 3, period: 1.minute) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  ### Prevent API Abuse ###
  # Throttle requests to create resources (offers, messages, reports)
  throttle("create_resources/ip", limit: 30, period: 1.minute) do |req|
    if req.post? && (req.path.include?("/offers") || req.path.include?("/messages") || req.path.include?("/reports"))
      req.ip
    end
  end

  ### Blocklist Bad IPs ###
  # Block requests from known bad IPs (add IPs to Rails.cache with prefix 'blocked_ip:')
  # Example: Rails.cache.write("blocked_ip:1.2.3.4", true, expires_in: 1.day)
  blocklist("block bad ips") do |req|
    begin
      Rack::Attack.cache.read("blocked_ip:#{req.ip}")
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
      # Cache table doesn't exist yet - allow request
      false
    end
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => (match_data[:period] - (now % match_data[:period])).to_s
    }

    [ 429, headers, [ { error: "Too many requests. Please try again later." }.to_json ] ]
  end

  ### ActiveSupport Notifications ###
  # Log throttled and blocked requests for monitoring
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled #{req.ip} for #{req.path}"
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Blocked #{req.ip} for #{req.path}"
  end
end

# Allow localhost in development/test
Rack::Attack.safelist("allow localhost") do |req|
  req.ip == "127.0.0.1" || req.ip == "::1"
end if Rails.env.development? || Rails.env.test?
