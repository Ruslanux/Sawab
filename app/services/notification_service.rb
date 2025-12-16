class NotificationService
  class << self
    # Уведомление при принятии оффера
    def notify_offer_accepted(offer)
      create_and_broadcast(
        recipient: offer&.user,
        actor: offer&.request&.user,
        notifiable: offer,
        action: "offer_accepted"
      )
    end

    # Уведомление при отклонении оффера
    def notify_offer_rejected(offer)
      create_and_broadcast(
        recipient: offer&.user,
        actor: offer&.request&.user,
        notifiable: offer,
        action: "offer_rejected"
      )
    end

    # Уведомление о новом оффере
    def notify_new_offer(offer)
      create_and_broadcast(
        recipient: offer&.request&.user,
        actor: offer&.user,
        notifiable: offer,
        action: "new_offer"
      )
    end

    # Уведомление о новом сообщении
    def notify_new_message(message)
      return unless message&.conversation

      recipient = message.user == message.conversation.asker ? message.conversation.helper : message.conversation.asker

      create_and_broadcast(
        recipient: recipient,
        actor: message.user,
        notifiable: message,
        action: "new_message"
      )
    end

    # Уведомление о завершении запроса
    def notify_request_completed(request)
      recipient = request&.offers&.accepted&.first&.user

      create_and_broadcast(
        recipient: recipient,
        actor: request&.user,
        notifiable: request,
        action: "request_completed"
      )
    end

    # Уведомление о том, что Хелпер ждет подтверждения
    def notify_pending_completion(request)
      create_and_broadcast(
        recipient: request&.user,
        actor: request&.accepted_offer&.user,
        notifiable: request,
        action: "pending_completion"
      )
    end

    # Сообщить РЕПОРТЕРУ, что его жалоба РЕШЕНА
    def notify_report_resolved(report)
      create_and_broadcast(
        recipient: report&.reporter,
        actor: report&.resolver,
        notifiable: report,
        action: "report_resolved"
      )
    end

    # Сообщить РЕПОРТЕРУ, что его жалоба ОТКЛОНЕНА
    def notify_report_dismissed(report)
      create_and_broadcast(
        recipient: report&.reporter,
        actor: report&.resolver,
        notifiable: report,
        action: "report_dismissed"
      )
    end

    # Сообщить ОБВИНЯЕМОМУ, что он получил ПРЕДУПРЕЖДЕНИЕ
    def notify_user_warned(report)
      recipient = find_warned_user(report)

      create_and_broadcast(
        recipient: recipient,
        actor: report&.resolver,
        notifiable: report,
        action: "user_warned"
      )
    end

    # Уведомление о разблокировке бейджа
    def notify_badge_unlocked(user, badge, actor: nil)
      create_and_broadcast(
        recipient: user,
        actor: actor || user,
        notifiable: badge,
        action: "badge_unlocked"
      )
    end

    # Уведомление админа о споре
    def notify_admin_of_dispute(request, admin)
      notification = create_and_broadcast(
        recipient: admin,
        actor: request&.user,
        notifiable: request,
        action: "dispute_created"
      )

      # Дополнительно сбрасываем кэш админ-сообщений
      admin&.clear_unread_admin_messages_cache if notification

      notification
    end

    # Уведомление о верификации учреждения
    def notify_institution_verified(institution, recipient)
      create_and_broadcast(
        recipient: recipient,
        actor: nil,
        notifiable: institution,
        action: "institution_verified"
      )
    end

    # Уведомление админам о новом учреждении на верификацию
    def notify_admins_new_institution(institution, creator)
      User.staff.find_each do |admin|
        create_and_broadcast(
          recipient: admin,
          actor: creator,
          notifiable: institution,
          action: "institution_pending_verification"
        )
      end
    end

    # Уведомление о новом запросе от учреждения
    def notify_institution_request_created(request)
      return unless request&.institution

      # Уведомляем всех членов учреждения, кроме автора запроса
      request.institution.members.where.not(id: request.user_id).find_each do |member|
        create_and_broadcast(
          recipient: member,
          actor: request.user,
          notifiable: request,
          action: "institution_request_created"
        )
      end
    end

    private

    def create_and_broadcast(recipient:, actor: nil, notifiable:, action:)
      return unless recipient && notifiable

      notification = Notification.create!(
        recipient: recipient,
        actor: actor,
        notifiable: notifiable,
        action: action
      )

      recipient.clear_unread_notifications_cache
      broadcast_notification(recipient, notification)

      notification
    rescue => e
      Rails.logger.error "NotificationService: Failed to create #{action} notification: #{e.message}"
      nil
    end

    def broadcast_notification(recipient, notification)
      NotificationsChannel.broadcast_to(
        recipient,
        notification: render_notification(notification)
      )
    end

    def render_notification(notification)
      ApplicationController.renderer.render(
        partial: "notifications/notification",
        locals: { notification: notification }
      )
    end

    def find_warned_user(report)
      return nil unless report

      # 1. Сначала ищем 'reported_user' (если он был задан при создании репорта)
      return report.reported_user if report.reported_user

      # 2. Если его нет, смотрим, не является ли 'reportable' сам по себе User
      return report.reportable if report.reportable.is_a?(User)

      # 3. Если 'reportable' - это Request или Offer, находим их автора
      return report.reportable.user if report.reportable.present? && report.reportable.respond_to?(:user)

      nil
    end
  end
end
