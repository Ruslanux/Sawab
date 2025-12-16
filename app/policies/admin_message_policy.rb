class AdminMessagePolicy < ApplicationPolicy
  # Разрешаем ли мы отвечать на это сообщение?
  def reply?
    # Да, если пользователь - получатель этого сообщения
    user.present? && record.recipient_id == user.id
  end

  # Разрешаем ли мы видеть этот чат?
  def show?
    user.present?
  end

  # Разрешаем ли мы видеть инбокс?
  def index?
    user.present?
  end

  # Разрешаем ли мы отправлять ответ?
  def create?
    user.present?
  end
end
