# frozen_string_literal: true

# Notifies admins about unresolved disputes that need attention
# Runs daily to ensure disputes don't go unnoticed
class DisputeEscalationJob < ApplicationJob
  queue_as :default

  # Escalate disputes older than this threshold
  ESCALATION_THRESHOLD = 3.days

  def perform
    disputed_requests = Request.disputed
                               .where("updated_at < ?", ESCALATION_THRESHOLD.ago)
                               .includes(:user, :offers)

    return if disputed_requests.empty?

    Rails.logger.info "[DisputeEscalationJob] Found #{disputed_requests.count} disputes needing escalation"

    # Notify all admins about pending disputes
    admins = User.admins

    disputed_requests.find_each do |request|
      admins.each do |admin|
        # Only notify if admin hasn't been notified about this dispute recently
        # Check both dispute_created and dispute_escalation actions
        recent_notification = Notification.where(
          recipient: admin,
          notifiable: request,
          action: %w[dispute_created dispute_escalation]
        ).where("created_at > ?", 1.day.ago).exists?

        next if recent_notification

        NotificationService.notify_admin_of_dispute(request, admin)
      end
    end

    Rails.logger.info "[DisputeEscalationJob] Completed escalation notifications"
  end
end
