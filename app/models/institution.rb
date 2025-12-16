# frozen_string_literal: true

class Institution < ApplicationRecord
  include TimeFilterable
  include Reportable

  # == Enums ==
  enum :institution_type, {
    children_center: 0,      # ЦПДСиС - Центр поддержки детей и семьи
    nursing_home: 1,         # Дом-интернат для престарелых и инвалидов
    care_facility: 2,        # Частный пансионат
    orphanage: 3,            # Детский дом
    disability_center: 4,    # Центр для людей с инвалидностью
    rehabilitation_center: 5, # Реабилитационный центр
    other: 6                 # Другое
  }, prefix: true

  # == Associations ==
  has_many :institution_members, dependent: :destroy
  has_many :members, through: :institution_members, source: :user
  has_many :requests, dependent: :nullify

  # == Validations ==
  validates :name, presence: true, length: { maximum: 255 }
  validates :institution_type, presence: true
  validates :address, presence: true, length: { maximum: 500 }
  validates :city, presence: true, length: { maximum: 100 }
  validates :region, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, length: { maximum: 50 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :director_name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # == Scopes ==
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :pending_verification, -> { unverified }
  scope :by_type, ->(type) { where(institution_type: type) if type.present? }
  scope :by_region, ->(region) { where("LOWER(region) = ?", region.downcase) if region.present? }
  scope :by_city, ->(city) { where("LOWER(city) = ?", city.downcase) if city.present? }
  scope :search, ->(query) {
    where("name ILIKE :q OR description ILIKE :q OR address ILIKE :q", q: "%#{query}%") if query.present?
  }
  scope :with_associations, -> { includes(:institution_members, :members) }

  # == Class Methods ==
  def self.filter_by(params)
    scope = all
    scope = scope.by_type(params[:institution_type]) if params[:institution_type].present?
    scope = scope.by_region(params[:region]) if params[:region].present?
    scope = scope.by_city(params[:city]) if params[:city].present?
    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.verified if params[:verified_only] == "true"
    scope
  end

  # == Instance Methods ==
  def verify!
    update!(verified: true, verified_at: Time.current)
  end

  def unverify!
    update!(verified: false, verified_at: nil)
  end

  def admin?(user)
    institution_members.exists?(user: user, role: :admin)
  end

  def member?(user)
    institution_members.exists?(user: user)
  end

  def representative?(user)
    institution_members.exists?(user: user, role: [ :admin, :representative ])
  end

  def full_address
    translated_region = I18n.t("regions.#{region}", default: region) if region.present?
    [ address, city, translated_region ].compact_blank.join(", ")
  end

  def contact_info
    info = []
    info << phone if phone.present?
    info << email if email.present?
    info << website if website.present?
    info.join(" | ")
  end
end
