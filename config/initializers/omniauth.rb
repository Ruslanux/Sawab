# frozen_string_literal: true

# OmniAuth configuration
# This file configures OmniAuth behavior for OAuth providers

Rails.application.config.middleware.use OmniAuth::Builder do
  # Configure origin whitelist for CSRF protection
  # Allow requests from our application's domain
  OmniAuth.config.allowed_request_methods = [ :post, :get ]
  OmniAuth.config.silence_get_warning = true

  # Full host for callbacks (required for correct redirect URIs)
  OmniAuth.config.full_host = lambda do |env|
    scheme = env["rack.url_scheme"]
    local_host = env["HTTP_HOST"]
    "#{scheme}://#{local_host}"
  end
end
