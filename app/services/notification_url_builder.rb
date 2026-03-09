# Builds target URLs for notifications based on the notifiable type and action.
# Extracted from Notification model to keep it focused on data and behavior.
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
