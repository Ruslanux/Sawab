class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true, length: { minimum: 1, maximum: 1000 }

  # Коллбэки для трансляции и уведомлений
  after_create_commit :broadcast_message
  after_create_commit :notify_recipient

  private

  def broadcast_message
    # Простой broadcast без current_user - стили применяются на клиенте
    broadcast_append_to(
      "conversation_#{conversation_id}",
      partial: "messages/message",
      locals: { message: self, viewing_user_id: nil },
      target: "messages"
    )
  end

  def notify_recipient
    # Создаём уведомление для получателя (не автора)
    return unless defined?(NotificationService)

    NotificationService.notify_new_message(self)
  end
end
