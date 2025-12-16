# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy
  # Все могут видеть список верифицированных учреждений
  def index?
    true
  end

  # Показываем только верифицированные учреждения публично
  # Админы и члены учреждения могут видеть неверифицированные
  def show?
    return true if record.verified?
    return true if user&.staff?
    return true if user.present? && record.member?(user)
    false
  end

  # Только залогиненные могут создавать учреждения
  def new?
    user.present?
  end

  def create?
    user.present?
  end

  # Только админ учреждения может редактировать
  def edit?
    user.present? && (record.admin?(user) || user.staff?)
  end

  def update?
    edit?
  end

  # Только админ учреждения или staff может удалять
  def destroy?
    user.present? && (record.admin?(user) || user.staff?)
  end

  # Управление членами учреждения
  def manage_members?
    user.present? && (record.admin?(user) || user.staff?)
  end

  # Может ли создавать запросы от имени учреждения
  def create_request?
    user.present? && record.verified? && record.representative?(user)
  end

  # Просмотр запросов учреждения
  def requests?
    show?
  end

  # Просмотр своих учреждений
  def my_institutions?
    user.present?
  end

  class Scope < Scope
    def resolve
      if user&.staff?
        # Админы видят все учреждения
        scope.all
      elsif user.present?
        # Пользователи видят верифицированные + свои учреждения
        scope.left_joins(:institution_members)
             .where("institutions.verified = ? OR institution_members.user_id = ?", true, user.id)
             .distinct
      else
        # Гости видят только верифицированные
        scope.verified
      end
    end
  end
end
