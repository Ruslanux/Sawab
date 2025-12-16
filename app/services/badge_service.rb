class BadgeService
  def self.award_badges_for(user, completed_request)
    new(user, completed_request).run
  end

  def initialize(user, completed_request)
    @user = user
    @completed_request = completed_request
    # Убеждаемся, что sawab_balance перезагружен после increment!
    @user_sawab = @user.reload.sawab_balance
    @category_name = @completed_request.category.name
  end

  def run
    # 1. Бейджи за количество Sawab
    award_badge_if_unlocked("Первый Sawab") { @user_sawab == 1 }
    award_badge_if_unlocked("Помощник") { @user_sawab == 5 }
    award_badge_if_unlocked("Ветеран") { @user_sawab == 25 }

    # 2. Бейджи за категории
    check_category_badges
  end

  private

  def check_category_badges
    # --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
    # Мы должны искать по `categories.name`, а не `requests.category_name`

    # Считаем, сколько раз юзер помогал в ЭТОЙ категории
    completed_in_category_count = @user.offers
                                      .accepted
                                      .joins(request: :category) # <-- ПРАВИЛЬНЫЙ JOIN
                                      .where(requests: { status: "completed" }, categories: { name: @category_name }) # <-- ПРАВИЛЬНЫЙ WHERE
                                      .count

    badge_name = "Эксперт: #{@category_name}"

    # Выдаем, если это 5-я помощь в этой категории (и бейдж с таким именем существует)
    award_badge_if_unlocked(badge_name) { completed_in_category_count == 5 }
  end

  # Хелпер, который проверяет, есть ли уже бейдж, и выдает его
  def award_badge_if_unlocked(badge_name, &block)
    # 1. Проверяем условие
    return unless yield

    # 2. Находим бейдж в БД
    badge = Badge.find_by(name: badge_name)
    # Если бейджа "Эксперт: Financial" нет в db/seeds.rb, он не будет выдан
    return unless badge

    # 3. Проверяем, что у юзера его еще нет
    return if UserBadge.exists?(user_id: @user.id, badge_id: badge.id)

    # 4. Выдаем бейдж
    @user.user_badges.create!(badge: badge, acquired_at: Time.current)
    Rails.logger.info "[BadgeService] Awarded '#{badge_name}' to #{@user.username}"

    # Отправляем уведомление о получении бейджа
    NotificationService.notify_badge_unlocked(@user, badge, actor: @user)
  end
end
