class NotificationPolicy < ApplicationPolicy
  def index?
    true # Любой авторизованный пользователь может видеть свои уведомления
  end

  def mark_as_read?
    user == record.recipient
  end

  def mark_all_as_read?
    true
  end

  def destroy?
    user == record.recipient
  end

  class Scope < Scope
    def resolve
      scope.where(recipient: user)
    end
  end
end
