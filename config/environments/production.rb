require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files in cloud storage (see config/storage.yml for options).
  # Options: :amazon (AWS S3), :digitalocean (DO Spaces), :local (not recommended for production)
  # Set STORAGE_SERVICE env var or defaults to :amazon
  config.active_storage.service = ENV.fetch("STORAGE_SERVICE", "amazon").to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Enable email delivery errors in production for debugging
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.perform_caching = false

  # Set host to be used by links generated in mailer templates.
  # APP_HOST should be set in your environment (e.g., "sawab.kz")
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost"),
    protocol: "https"
  }

  # Asset host for emails (images, etc.)
  config.action_mailer.asset_host = "https://#{ENV.fetch('APP_HOST', 'localhost')}"

  # SMTP configuration - credentials stored in Rails credentials
  # Run: EDITOR=nano bin/rails credentials:edit
  # Add:
  #   smtp:
  #     user_name: your_smtp_username
  #     password: your_smtp_password
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: Rails.application.credentials.dig(:smtp, :user_name),
    password: Rails.application.credentials.dig(:smtp, :password),
    address: ENV.fetch("SMTP_ADDRESS", "smtp.sendgrid.net"),
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    authentication: :plain,
    enable_starttls_auto: true,
    domain: ENV.fetch("APP_HOST", "localhost")
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # Only allow requests from your configured domain
  config.hosts = [
    ENV.fetch("APP_HOST", "localhost"),                    # Main domain (e.g., sawab.kz)
    /.*\.#{Regexp.escape(ENV.fetch("APP_HOST", "localhost"))}/ # Subdomains (e.g., www.sawab.kz)
  ]

  # Skip DNS rebinding protection for the health check endpoint
  # This is needed for Kamal's health checks and load balancers
  config.host_authorization = {
    exclude: ->(request) {
      request.path == "/up" || request.path == "/health"
    }
  }
end
