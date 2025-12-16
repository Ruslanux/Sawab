# frozen_string_literal: true

class InstitutionMemberPolicy < ApplicationPolicy
  def index?
    user.present? && (record.institution.admin?(user) || user.staff?)
  end

  def show?
    user.present? && (record.institution.member?(user) || user.staff?)
  end

  def create?
    user.present? && (record.institution.admin?(user) || user.staff?)
  end

  def update?
    create?
  end

  def destroy?
    return false unless user.present?
    return true if user.staff?
    return true if record.institution.admin?(user) && record.user != user
    # Админ не может удалить сам себя если он единственный админ
    false
  end

  class Scope < Scope
    def resolve
      if user&.staff?
        scope.all
      elsif user.present?
        # Пользователь видит членов учреждений, в которых он состоит
        scope.joins(:institution)
             .joins("INNER JOIN institution_members AS user_membership ON user_membership.institution_id = institutions.id")
             .where("user_membership.user_id = ?", user.id)
      else
        scope.none
      end
    end
  end
end
