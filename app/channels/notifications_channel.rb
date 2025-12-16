class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # stream_for works with broadcast_to(recipient, ...)
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
