# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   :self
    policy.base_uri    :self
    policy.form_action :self

    # Allow WebSocket connections for Action Cable
    if Rails.env.development?
      policy.connect_src :self, :https, "http://localhost:*", "ws://localhost:*", "wss://localhost:*"
    else
      # In production, allow WSS connections to your domain
      policy.connect_src :self, :https, "wss://#{ENV.fetch('APP_HOST', 'localhost')}"
    end

    # Allow images from S3/DigitalOcean Spaces if using cloud storage
    if ENV["STORAGE_SERVICE"] == "amazon"
      policy.img_src :self, :https, :data, :blob, "https://*.s3.amazonaws.com", "https://*.s3.*.amazonaws.com"
    elsif ENV["STORAGE_SERVICE"] == "digitalocean"
      policy.img_src :self, :https, :data, :blob, "https://*.digitaloceanspaces.com"
    end

    # Specify URI for violation reports (optional - useful for monitoring)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing the policy (useful during initial rollout).
  # Set to false once you've verified the policy works correctly.
  # config.content_security_policy_report_only = true
end
