module Requests
  class MarkPendingService < ApplicationService
    attr_reader :request

    def initialize(request)
      super()
      @request = request
    end

    def call
      if request.update(status: "pending_completion", pending_completion_at: Time.current)
        NotificationService.notify_pending_completion(request)
        true
      else
        add_errors(request.errors.full_messages)
        false
      end
    end
  end
end
