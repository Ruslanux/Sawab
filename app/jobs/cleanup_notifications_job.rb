# frozen_string_literal: true

# Cleans up old read notifications to keep the database size manageable.
# Unread notifications are preserved regardless of age.
class CleanupNotificationsJob < ApplicationJob
  queue_as :default

  # Delete read notifications older than this
  RETENTION_PERIOD = 30.days

  # Batch size for deletion to avoid locking
  BATCH_SIZE = 1000

  def perform
    cutoff_date = RETENTION_PERIOD.ago

    # Only delete read notifications
    old_notifications = Notification.read
                                    .where("created_at < ?", cutoff_date)

    total_count = old_notifications.count

    return if total_count.zero?

    Rails.logger.info "[CleanupNotificationsJob] Deleting #{total_count} old notifications"

    deleted_count = 0

    # Delete in batches to avoid long locks
    loop do
      batch = old_notifications.limit(BATCH_SIZE)
      break if batch.empty?

      deleted = batch.delete_all
      deleted_count += deleted

      # Small pause between batches to reduce database load
      sleep(0.1) if deleted == BATCH_SIZE
    end

    Rails.logger.info "[CleanupNotificationsJob] Deleted #{deleted_count} notifications"
  end
end
