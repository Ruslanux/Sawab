class ConversationsController < ApplicationController
  before_action :set_request
  before_action :set_conversation, only: :show
  before_action :authorize_conversation, only: :show

  def show
    unless @conversation
      redirect_to @request, alert: t(".no_conversation")
      return
    end

    @messages = @conversation.messages.includes(:user).order(created_at: :asc)
    @message = @conversation.messages.build

    mark_message_notifications_as_read
  end

  private

  def set_request
    @request = Request.find(params[:request_id])
  end

  def set_conversation
    accepted_offer = @request.offers.accepted.first
    return unless accepted_offer

    @conversation = Conversation.find_or_create_by!(
      request: @request,
      asker: @request.user,
      helper: accepted_offer.user
    )
  end

  def authorize_conversation
    return unless @conversation
    return if @conversation.participant?(current_user)

    redirect_to root_path, alert: t(".unauthorized")
  end

  def mark_message_notifications_as_read
    return unless @conversation

    message_ids = @conversation.messages.pluck(:id)
    return if message_ids.empty?

    Notification.where(
      recipient: current_user,
      notifiable_type: "Message",
      action: "new_message",
      notifiable_id: message_ids,
      read_at: nil
    ).update_all(read_at: Time.current)

    current_user.clear_unread_notifications_cache
  end
end
