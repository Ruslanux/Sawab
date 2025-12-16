class Notification < ApplicationRecord
  include Readable

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true

  ACTIONS = %w[
    new_offer offer_accepted offer_rejected new_message
    pending_completion request_completed report_resolved
    report_dismissed user_warned badge_unlocked dispute_created
    request_auto_completed inactive_request_reminder dispute_escalation
    institution_pending_verification institution_verified institution_request_created
  ].freeze

  validates :action, inclusion: { in: ACTIONS }

  # Override to clear cache after marking as read
  def mark_as_read!
    return if read?

    update(read_at: Time.current)
    recipient.clear_unread_notifications_cache
  end

  def broadcast_to_recipient
    NotificationsChannel.broadcast_to(
      recipient,
      {
        id: id,
        message: display_message,
        action: action,
        url: target_url,
        created_at: created_at.iso8601,
        read: read?
      }
    )
  end

  def display_message
    return read_attribute(:message) if read_attribute(:message).present?

    I18n.t("notifications.#{action}", default: default_message, **message_interpolations)
  end
  alias_method :message, :display_message

  def target_url
    NotificationUrlBuilder.new(self).url
  end
  alias_method :url, :target_url

  def icon
    ICONS[action] || ICONS[:default]
  end

  def color_class
    COLORS[action] || COLORS[:default]
  end

  private

  ICONS = {
    "new_offer" => "briefcase",
    "offer_accepted" => "check-circle",
    "offer_rejected" => "x-circle",
    "new_message" => "chat-bubble-left",
    "request_completed" => "trophy",
    "pending_completion" => "clock",
    "badge_unlocked" => "star",
    "dispute_created" => "exclamation-triangle",
    "request_auto_completed" => "check-circle",
    "inactive_request_reminder" => "clock",
    "dispute_escalation" => "exclamation-triangle",
    "institution_pending_verification" => "building-office",
    "institution_verified" => "check-badge",
    "institution_request_created" => "document-plus",
    :default => "bell"
  }.freeze

  COLORS = {
    "new_offer" => "bg-blue-100 text-blue-800",
    "offer_accepted" => "bg-green-100 text-green-800",
    "offer_rejected" => "bg-red-100 text-red-800",
    "new_message" => "bg-purple-100 text-purple-800",
    "request_completed" => "bg-yellow-100 text-yellow-800",
    "pending_completion" => "bg-orange-100 text-orange-800",
    "badge_unlocked" => "bg-indigo-100 text-indigo-800",
    "request_auto_completed" => "bg-green-100 text-green-800",
    "inactive_request_reminder" => "bg-amber-100 text-amber-800",
    "dispute_escalation" => "bg-red-100 text-red-800",
    "institution_pending_verification" => "bg-emerald-100 text-emerald-800",
    "institution_verified" => "bg-green-100 text-green-800",
    "institution_request_created" => "bg-teal-100 text-teal-800",
    :default => "bg-gray-100 text-gray-800"
  }.freeze

  def default_message
    I18n.t("notifications.messages.#{action}",
      actor_name: actor_name,
      title: notifiable&.try(:title),
      name: notifiable&.try(:name),
      resolution_note: notifiable&.try(:resolution_note),
      institution_name: notifiable&.try(:institution)&.try(:name),
      default: I18n.t("notifications.messages.default"))
  end

  def message_interpolations
    {
      actor_name: actor_name,
      notifiable_name: notifiable&.try(:name) || notifiable&.try(:title),
      resolution_note: notifiable&.try(:resolution_note)
    }.compact
  end

  def actor_name
    actor&.username || "Someone"
  end
end

# Separate class for URL building to reduce Notification model complexity
class NotificationUrlBuilder
  include Rails.application.routes.url_helpers

  def initialize(notification)
    @notification = notification
    @notifiable = notification.notifiable
    @action = notification.action
  end

  def url
    return root_path unless @notifiable

    case @notification.notifiable_type
    when "Offer"
      request_path(id: @notifiable.request_id)
    when "Request"
      request_url_for_action
    when "Message"
      message_url
    when "Report"
      report_url
    when "Badge"
      badge_url
    when "Institution"
      institution_url
    else
      root_path
    end
  rescue => e
    Rails.logger.error "Error generating notification URL: #{e.message}"
    root_path
  end

  private

  def request_url_for_action
    if @action == "dispute_created"
      admin_request_path(id: @notifiable.id)
    else
      request_path(id: @notifiable.id)
    end
  end

  def message_url
    return root_path unless @notifiable.conversation

    request_conversation_path(request_id: @notifiable.conversation.request_id)
  end

  def report_url
    return root_path if @action == "user_warned"
    return root_path unless @notifiable.reportable

    if @notifiable.reportable.is_a?(::Request)
      request_path(id: @notifiable.reportable_id)
    elsif @notifiable.reportable.is_a?(::User)
      user_path(username: @notifiable.reportable.username)
    else
      root_path
    end
  end

  def badge_url
    user_path(username: @notification.recipient.username, anchor: "badges")
  end

  def institution_url
    if @action == "institution_pending_verification"
      admin_institution_path(id: @notifiable.id)
    else
      institution_path(id: @notifiable.id)
    end
  end
end
