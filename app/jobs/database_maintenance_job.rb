# frozen_string_literal: true

# Performs regular database maintenance tasks:
# - Cleans up old Solid Cable messages
# - Cleans up old Solid Cache entries
# - Cleans up old Active Storage blobs without attachments
class DatabaseMaintenanceJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[DatabaseMaintenanceJob] Starting maintenance tasks"

    cleanup_solid_cable
    cleanup_orphaned_blobs
    cleanup_old_admin_messages

    Rails.logger.info "[DatabaseMaintenanceJob] Maintenance completed"
  end

  private

  # Clean up old Solid Cable messages
  def cleanup_solid_cable
    return unless defined?(SolidCable::Message)

    # Keep messages for 1 day (matching cable.yml config)
    cutoff = 1.day.ago
    deleted = SolidCable::Message.where("created_at < ?", cutoff).delete_all

    Rails.logger.info "[DatabaseMaintenanceJob] Deleted #{deleted} old cable messages"
  rescue => e
    Rails.logger.error "[DatabaseMaintenanceJob] Solid Cable cleanup failed: #{e.message}"
  end

  # Clean up orphaned Active Storage blobs
  def cleanup_orphaned_blobs
    return unless defined?(ActiveStorage::Blob)

    # Find blobs without attachments older than 1 day
    cutoff = 1.day.ago

    orphaned_blobs = ActiveStorage::Blob
                       .left_joins(:attachments)
                       .where(active_storage_attachments: { id: nil })
                       .where("active_storage_blobs.created_at < ?", cutoff)

    count = orphaned_blobs.count
    return if count.zero?

    Rails.logger.info "[DatabaseMaintenanceJob] Found #{count} orphaned blobs"

    # Purge blobs (this also deletes files from storage)
    orphaned_blobs.find_each do |blob|
      blob.purge
    rescue => e
      Rails.logger.error "[DatabaseMaintenanceJob] Failed to purge blob #{blob.id}: #{e.message}"
    end

    Rails.logger.info "[DatabaseMaintenanceJob] Purged orphaned blobs"
  rescue => e
    Rails.logger.error "[DatabaseMaintenanceJob] Blob cleanup failed: #{e.message}"
  end

  # Clean up old read admin messages
  def cleanup_old_admin_messages
    # Keep read admin messages for 90 days
    cutoff = 90.days.ago

    deleted = AdminMessage.read
                          .where("created_at < ?", cutoff)
                          .delete_all

    Rails.logger.info "[DatabaseMaintenanceJob] Deleted #{deleted} old admin messages"
  rescue => e
    Rails.logger.error "[DatabaseMaintenanceJob] Admin message cleanup failed: #{e.message}"
  end
end
