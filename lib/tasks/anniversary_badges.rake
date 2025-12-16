namespace :users do
  desc "Выдает награду 'Год на Sawab' всем пользователям, которые зарегистрированы больше 1 года"
  task award_anniversary_badges: :environment do
    puts "Запуск задачи: award_anniversary_badges..."

    # 1. Находим нужный бейдж в БД
    badge_to_award = Badge.find_by(name: "Год на Sawab")

    unless badge_to_award
      puts "ОШИБКА: Бейдж 'Год на Sawab' не найден. Сначала запусти 'bin/rails db:seed'."
      next
    end

    # 2. Находим всех пользователей, которые:
    #    - Зарегистрированы 1 год назад или раньше
    #    - (Мы могли бы также исключить забаненных, если нужно)
    eligible_users = User.where("created_at <= ?", 1.year.ago)

    # 3. Находим ID пользователей, у которых УЖЕ есть этот бейдж
    existing_user_ids = UserBadge.where(badge_id: badge_to_award.id).pluck(:user_id)

    # 4. Вычисляем, кому реально нужно выдать награду
    users_to_award = eligible_users.where.not(id: existing_user_ids)

    if users_to_award.empty?
      puts "Нет новых пользователей для награждения."
      next
    end

    puts "Найдено #{users_to_award.count} пользователей для награждения..."

    # 5. Выдаем награды
    users_to_award.each do |user|
      begin
        user.user_badges.create!(badge: badge_to_award, acquired_at: Time.current)
        puts "-> Награжден: #{user.username} (ID: #{user.id})"

        # TODO: Отправить уведомление пользователю!
        # NotificationService.notify_badge_unlocked(user, badge_to_award)

      rescue ActiveRecord::RecordInvalid => e
        # Эта ошибка сработает, если (вдруг) мы все же попытались создать дубликат
        puts "-> ОШИБКА для #{user.username}: #{e.message}"
      end
    end

    puts "Задача 'award_anniversary_badges' завершена."
  end
end
