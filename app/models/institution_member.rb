# frozen_string_literal: true

class InstitutionMember < ApplicationRecord
  # == Enums ==
  enum :role, {
    member: 0,           # Обычный член учреждения
    representative: 1,   # Представитель (может создавать запросы)
    admin: 2             # Администратор учреждения
  }, prefix: true

  # == Associations ==
  belongs_to :user
  belongs_to :institution

  # == Validations ==
  validates :user_id, uniqueness: { scope: :institution_id, message: :already_member }
  validates :role, presence: true
  validates :position, length: { maximum: 255 }

  # == Scopes ==
  scope :admins, -> { where(role: :admin) }
  scope :representatives, -> { where(role: [ :admin, :representative ]) }
  scope :can_create_requests, -> { representatives }

  # == Instance Methods ==
  def can_create_requests?
    role_admin? || role_representative?
  end

  def can_manage_institution?
    role_admin?
  end
end
