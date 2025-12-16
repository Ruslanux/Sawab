# frozen_string_literal: true

# Automatically completes requests that have been in pending_completion status
# for longer than the threshold without asker confirmation.
#
# This ensures helpers get their sawab even if the asker doesn't confirm.
class AutoCompleteRequestsJob < ApplicationJob
  queue_as :default

  # Auto-complete after this many days in pending_completion
  AUTO_COMPLETE_THRESHOLD = 7.days

  def perform
    pending_requests = Request.pending_completion
                              .where("pending_completion_at < ?", AUTO_COMPLETE_THRESHOLD.ago)
                              .includes(:user, offers: :user)

    return if pending_requests.empty?

    Rails.logger.info "[AutoCompleteRequestsJob] Found #{pending_requests.count} requests for auto-completion"

    completed_count = 0
    failed_count = 0

    pending_requests.find_each do |request|
      service = Requests::CompleteService.new(request)

      if service.call
        completed_count += 1
        Rails.logger.info "[AutoCompleteRequestsJob] Auto-completed request ##{request.id}"

        # Notify asker that request was auto-completed
        create_auto_completion_notification(request)
      else
        failed_count += 1
        Rails.logger.error "[AutoCompleteRequestsJob] Failed to auto-complete request ##{request.id}: #{service.error_message}"
      end
    end

    Rails.logger.info "[AutoCompleteRequestsJob] Completed: #{completed_count}, Failed: #{failed_count}"
  end

  private

  def create_auto_completion_notification(request)
    Notification.create(
      recipient: request.user,
      actor: request.accepted_offer&.user,
      notifiable: request,
      action: "request_auto_completed"
    )
    request.user.clear_unread_notifications_cache
  rescue => e
    Rails.logger.error "[AutoCompleteRequestsJob] Failed to create notification: #{e.message}"
  end
end
