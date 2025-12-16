# frozen_string_literal: true

# Sentry error tracking and performance monitoring
# https://docs.sentry.io/platforms/ruby/guides/rails/
#
# Setup:
# 1. Create a free account at https://sentry.io
# 2. Create a new Rails project
# 3. Get your DSN from Settings > Client Keys (DSN)
# 4. Add to Rails credentials: bin/rails credentials:edit
#    sentry:
#      dsn: https://your-dsn@sentry.io/project-id
#
# Or set via environment variable:
#   SENTRY_DSN=https://your-dsn@sentry.io/project-id

if Rails.env.production? && ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]

    # Set environment name
    config.environment = Rails.env

    # Enable performance monitoring (traces)
    # Set to 1.0 for all requests, lower for sampling
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f

    # Enable session tracking
    config.auto_session_tracking = true

    # Set release version (optional, useful for tracking deployments)
    config.release = ENV.fetch("SENTRY_RELEASE", `git rev-parse HEAD`.strip) rescue nil

    # Breadcrumbs configuration
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # Filter out sensitive data
    config.before_send = lambda do |event, hint|
      # Don't send events for common user errors
      if hint[:exception].is_a?(ActiveRecord::RecordNotFound)
        return nil
      end

      # Filter out health check errors
      if event.request&.url&.include?("/up")
        return nil
      end

      event
    end

    # Additional context
    config.before_send_transaction = lambda do |event, _hint|
      # Skip health check transactions
      if event.transaction == "Rails::HealthController#show"
        return nil
      end

      event
    end

    # Exclude these exceptions from being reported
    config.excluded_exceptions += [
      "ActionController::RoutingError",
      "ActionController::InvalidAuthenticityToken",
      "ActionController::BadRequest"
    ]

    # Background worker configuration
    config.background_worker_threads = 1
  end
end

# Also initialize Sentry in staging if SENTRY_DSN is set
if Rails.env.staging? && ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = "staging"
    config.traces_sample_rate = 0.2
  end
end
