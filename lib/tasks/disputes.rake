namespace :requests do
  desc "Эскалация запросов, ожидающих подтверждения более 3 дней"
  task escalate_disputes: :environment do
    puts "Running dispute escalation task..."

    # 1. Находим запросы, которые "зависли"
    # (Для теста ты можешь временно поменять '3.days.ago' на '1.minute.ago')
    requests_to_escalate = Request.where(status: "pending_completion")
                                  .where("pending_completion_at < ?", 3.days.ago)

    if requests_to_escalate.empty?
      puts "No requests to escalate."
      next
    end

    puts "Escalating #{requests_to_escalate.count} requests..."

    # 2. Обновляем их статус и уведомляем админов
    requests_to_escalate.each do |request|
      if request.update(status: "disputed")
        # Отправляем уведомление всем Админам
        User.staff.each do |admin|
          NotificationService.notify_admin_of_dispute(request, admin)
          # ========================
        end
        puts "Request ##{request.id} escalated to 'disputed'."
      end
    end

    puts "Task finished."
  end
end
