# frozen_string_literal: true

# Sends reminders to helpers about requests that have been in_progress
# for a while without completion. Encourages them to either complete
# the work or mark it as pending completion.
class InactiveRequestReminderJob < ApplicationJob
  queue_as :default

  # Remind after this many days of inactivity
  REMINDER_THRESHOLD = 5.days

  # Don't send more than one reminder per this period
  REMINDER_COOLDOWN = 3.days

  def perform
    inactive_requests = Request.in_progress
                               .where("updated_at < ?", REMINDER_THRESHOLD.ago)
                               .includes(:user, offers: :user)

    return if inactive_requests.empty?

    Rails.logger.info "[InactiveRequestReminderJob] Found #{inactive_requests.count} inactive requests"

    reminder_count = 0

    inactive_requests.find_each do |request|
      helper = request.accepted_offer&.user
      next unless helper

      # Check if we've already sent a reminder recently
      recent_reminder = Notification.where(
        recipient: helper,
        notifiable: request,
        action: "inactive_request_reminder"
      ).where("created_at > ?", REMINDER_COOLDOWN.ago).exists?

      next if recent_reminder

      # Send reminder to helper
      Notification.create!(
        recipient: helper,
        actor: request.user,
        notifiable: request,
        action: "inactive_request_reminder"
      )
      helper.clear_unread_notifications_cache

      reminder_count += 1
      Rails.logger.info "[InactiveRequestReminderJob] Sent reminder for request ##{request.id} to #{helper.username}"
    rescue => e
      Rails.logger.error "[InactiveRequestReminderJob] Error for request ##{request.id}: #{e.message}"
    end

    Rails.logger.info "[InactiveRequestReminderJob] Sent #{reminder_count} reminders"
  end
end
