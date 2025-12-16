module ApplicationCable
  class Channel < ActionCable::Channel::Base
    private

    # Reject subscription with debug logging
    def reject_subscription(reason)
      Rails.logger.debug { "[#{self.class.name}] Subscription rejected: #{reason}" }
      reject
    end
  end
end
