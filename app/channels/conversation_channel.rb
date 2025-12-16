class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation_id = params[:id]

    if conversation_id.blank?
      reject_subscription("No conversation ID provided")
      return
    end

    @conversation = Conversation.find(conversation_id)

    unless @conversation.participant?(current_user)
      reject_subscription("User #{current_user.id} is not a participant")
      return
    end

    # Stream name matches Turbo's broadcast_append_to format
    stream_from "conversation_#{@conversation.id}"
  rescue ActiveRecord::RecordNotFound
    reject_subscription("Conversation #{conversation_id} not found")
  end

  def unsubscribed
    stop_all_streams
  end
end
