class OfferPolicy < ApplicationPolicy
  # Создавать офферы могут залогиненные пользователи,
  # но не на свои запросы и только на открытые запросы
  def create?
    return false unless user.present?
    return false unless record.request.present?

    user != record.request.user && record.request.status == "open"
  end

  # Обновлять статус (accept/reject) может только автор запроса
  # Условия:
  # - Оффер должен быть в статусе 'pending'
  # - Запрос должен быть в статусе 'open'
  def update?
    return false unless user.present?
    return false unless record.request.present?

    user == record.request.user &&
    record.status == "pending" &&
    record.request.status == "open"
  end

  # Удалять офферы может только автор оффера
  # И только если оффер еще pending
  def destroy?
    user.present? &&
    user == record.user &&
    record.status == "pending"
  end
end
