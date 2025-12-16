class RequestPolicy < ApplicationPolicy
  # Все могут видеть список запросов (публичная платформа помощи)
  def index?
    true
  end

  # Все могут видеть детали запросов
  def show?
    true
  end

  # Только залогиненные могут создавать запросы
  def new?
    user.present?
  end

  def create?
    user.present?
  end

  # Только автор может редактировать свой запрос
  # И только если статус 'open' (нельзя редактировать в процессе или завершенные)
  def edit?
    user.present? && user == record.user && record.status == "open"
  end

  def update?
    edit?
  end

  # Только автор может удалять свой запрос
  # И только если статус 'open' (нельзя удалять запросы в процессе)
  def destroy?
    user.present? && user == record.user && record.status == "open"
  end

  def complete?
    return false unless user.present?
    has_accepted_offer = record.offers.exists?(status: "accepted")
    return false unless has_accepted_offer

    # --- Логика для Автора Запроса (Asker) ---
    is_asker = (user == record.user)
    is_asker_status = (record.in_progress? || record.pending_completion?)
    asker_can_complete = (is_asker && is_asker_status)

    # --- Логика для Админа (для решения споров) ---
    is_admin = user.staff?
    is_admin_status = (record.pending_completion? || record.disputed?)
    admin_can_complete = (is_admin && is_admin_status)

    (asker_can_complete || admin_can_complete)
  end

  def cancel?
    return false unless user.present?

    # --- Логика для Автора Запроса (Asker) ---
    is_asker = (user == record.user)
    is_asker_status = (record.open? || record.in_progress? || record.pending_completion?)
    asker_can_cancel = (is_asker && is_asker_status)

    # --- Логика для Админа (для решения споров) ---
    is_admin = user.staff?
    is_admin_status = (record.pending_completion? || record.disputed? || record.in_progress? || record.open?)
    admin_can_cancel = (is_admin && is_admin_status)

    # Отменить может ЛИБО Аскер, ЛИБО Админ
    asker_can_cancel || admin_can_cancel
  end

  def mark_pending_completion?
    return false unless user.present?

    record.in_progress? &&
      record.accepted_offer&.user == user &&
      record.updated_at < 7.days.ago  # Правило 7 дней: Запрос был 'in_progress' более 7 дней
  end

  # Scope для index: показываем открытые запросы + все свои запросы
  class Scope < Scope
    def resolve
      if user.present?
        # Авторизованные пользователи видят:
        # - Все открытые запросы (чтобы помогать другим)
        # - Все свои запросы (независимо от статуса)
        scope.where(status: "open")
             .or(scope.where(user: user))
             .distinct
             .order(created_at: :desc)
      else
        # Гости видят только открытые запросы
        scope.where(status: "open").order(created_at: :desc)
      end
    end
  end
end
