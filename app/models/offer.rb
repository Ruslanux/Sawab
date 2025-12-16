class Offer < ApplicationRecord
  include TimeFilterable
  include Statusable
  include Reportable
  include StatusDisplayable

  STATUSES = %w[pending accepted rejected].freeze

  define_status_colors(
    "pending" => "yellow",
    "accepted" => "green",
    "rejected" => "red"
  )

  belongs_to :user
  belongs_to :request, counter_cache: true

  validates :message, presence: true, length: { minimum: 10, maximum: 500 }
  validates :status, inclusion: { in: STATUSES, message: "%{value} is not a valid status" }

  validate :helper_is_not_asker
  validate :request_must_be_open, on: :create
  validate :cannot_create_duplicate_pending_offer, on: :create

  # Define explicit status check methods: pending?, accepted?, rejected?
  define_status_methods STATUSES

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО СТАТУСУ
  # ============================================
  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :rejected, -> { where(status: "rejected") }
  # with_status scope provided by Statusable concern

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО ВРЕМЕНИ
  # ============================================
  # Time-based scopes provided by TimeFilterable concern

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО ПОЛЬЗОВАТЕЛЮ
  # ============================================
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :for_user, ->(user) { where(user: user) if user.present? }

  # ============================================
  # КОМПЛЕКСНЫЙ SCOPE ДЛЯ ПРИМЕНЕНИЯ ВСЕХ ФИЛЬТРОВ
  # ============================================
  scope :filter_by, ->(params) {
    offers = all
    offers = offers.with_status(params[:status]) if params[:status].present?
    offers = offers.by_time_period(params[:time_period] || "all")
    offers = offers.by_user(params[:user_id]) if params[:user_id].present?
    offers
  }

  # ============================================
  # EAGER LOADING
  # ============================================
  scope :with_associations, -> { includes(:user, :request) }

  # ============================================
  # СОРТИРОВКА
  # ============================================
  # recent and oldest scopes provided by TimeFilterable concern

  # ============================================
  # STATUS HELPER METHODS
  # ============================================
  # Status helper methods (pending?, accepted?, rejected?) provided by Statusable concern

  # ============================================
  # СТАТИСТИЧЕСКИЕ МЕТОДЫ
  # ============================================
  # status_counts provided by Statusable concern

  # ============================================
  # МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ДОСТУПОМ
  # ============================================
  def editable_by?(current_user)
    user == current_user && pending?
  end

  def acceptable_by?(current_user)
    request.user == current_user && pending?
  end

  def rejectable_by?(current_user)
    request.user == current_user && pending?
  end

  def can_be_deleted_by?(current_user)
    user == current_user && pending?
  end

  # ============================================
  # ПЕРЕХОДЫ СТАТУСОВ
  # ============================================
  # For full accept flow with notifications, use Offers::AcceptService
  # This method provides basic accept functionality for convenience
  def accept!
    transaction do
      # Reject all other pending offers on this request
      request.offers.pending.where.not(id: id).update_all(
        status: "rejected",
        updated_at: Time.current
      )
      # Accept this offer
      update!(status: "accepted")
      # Update request status to in_progress
      request.update!(status: "in_progress")
    end
  end

  def reject!
    update!(status: "rejected")
  end


  private

  def helper_is_not_asker
    if user_id == request&.user_id
      errors.add(:user, "cannot offer help on their own request")
    end
  end

  def request_must_be_open
    unless request&.status == "open"
      errors.add(:request, "must be open to create offers")
    end
  end

  def cannot_create_duplicate_pending_offer
    if request && user && request.offers.where(user: user, status: "pending").exists?
      errors.add(:base, "You already have a pending offer on this request")
    end
  end
end
