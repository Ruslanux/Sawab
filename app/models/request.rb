class Request < ApplicationRecord
  include TimeFilterable
  include Statusable
  include Reportable
  include StatusDisplayable

  STATUSES = %w[open in_progress completed cancelled pending_completion disputed].freeze

  define_status_colors(
    "open" => "blue",
    "in_progress" => "yellow",
    "completed" => "green",
    "cancelled" => "red",
    "pending_completion" => "orange",
    "disputed" => "purple"
  )

  # == Enums ==
  enum :help_type, {
    general: 0,           # Общая помощь учреждению
    specific_person: 1,   # Помощь конкретному человеку
    volunteering: 2,      # Волонтерская работа
    material_help: 3,     # Материальная помощь
    educational: 4,       # Образовательная помощь
    medical: 5,           # Медицинская помощь
    entertainment: 6      # Развлекательные мероприятия
  }, prefix: true

  # == Associations ==
  belongs_to :user
  belongs_to :category
  belongs_to :institution, optional: true
  has_many :offers, dependent: :destroy
  has_one :conversation, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 20 }
  validates :category_id, presence: true
  validates :region, presence: true
  validates :city, presence: true
  validates :status, inclusion: { in: STATUSES, message: "%{value} is not a valid status" }
  validates :beneficiary_name, length: { maximum: 255 }, allow_blank: true
  validates :beneficiary_age, numericality: { only_integer: true, greater_than: 0, less_than: 150 }, allow_nil: true
  validates :author_name, presence: true, if: :institution_request?
  validates :author_name, length: { maximum: 255 }, allow_blank: true

  # Define explicit status check methods: open?, in_progress?, completed?, etc.
  define_status_methods STATUSES

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО СТАТУСУ
  # ============================================
  scope :open_requests, -> { where(status: "open").order(created_at: :desc) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :pending_completion, -> { where(status: "pending_completion") }
  scope :disputed, -> { where(status: "disputed") }
  # with_status scope provided by Statusable concern

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО КАТЕГОРИИ
  # ============================================
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО ВРЕМЕНИ
  # ============================================
  # Time-based scopes provided by TimeFilterable concern

  # ============================================
  # SCOPES ДЛЯ ФИЛЬТРАЦИИ ПО ЛОКАЦИИ
  # ============================================
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_city, ->(city) {
    where("LOWER(requests.city) LIKE ?", "%#{city.to_s.downcase}%") if city.present?
  }

  # ============================================
  # SCOPES ДЛЯ УЧРЕЖДЕНИЙ
  # ============================================
  scope :institution_requests, -> { where.not(institution_id: nil) }
  scope :personal_requests, -> { where(institution_id: nil) }
  scope :by_institution, ->(institution_id) { where(institution_id: institution_id) if institution_id.present? }
  scope :by_help_type, ->(help_type) { where(help_type: help_type) if help_type.present? }

  # ============================================
  # КОМПЛЕКСНЫЙ SCOPE ДЛЯ ПРИМЕНЕНИЯ ВСЕХ ФИЛЬТРОВ
  # ============================================
  scope :filter_by, ->(params) {
    requests = all
    requests = requests.with_status(params[:status]) if params[:status].present?
    requests = requests.by_category(params[:category_id]) if params[:category_id].present?
    requests = requests.by_time_period(params[:time_period] || "all")
    requests = requests.by_region(params[:region]) if params[:region].present?
    requests = requests.by_city(params[:city]) if params[:city].present?
    requests = requests.by_institution(params[:institution_id]) if params[:institution_id].present?
    requests = requests.by_help_type(params[:help_type]) if params[:help_type].present?
    requests = requests.institution_requests if params[:institution_only] == "true"
    requests
  }

  # ============================================
  # SCOPE ДЛЯ ПОИСКА
  # ============================================
  scope :search, ->(query) {
    if query.present?
      where("LOWER(requests.title) LIKE ? OR LOWER(requests.description) LIKE ?",
            "%#{query.to_s.downcase}%", "%#{query.to_s.downcase}%")
    end
  }

  # ============================================
  # EAGER LOADING
  # ============================================
  scope :with_associations, -> { includes(:user, :category, :institution) }
  scope :with_full_associations, -> { includes(:user, :category, :institution, offers: :user) }

  # ============================================
  # СОРТИРОВКА
  # ============================================
  # recent and oldest scopes provided by TimeFilterable concern
  scope :by_sawab, -> {
    joins(user: :offers)
      .group("requests.id")
      .order("COUNT(offers.id) DESC")
  }

  # ============================================
  # STATUS HELPER METHODS
  # ============================================
  # Status helper methods (open?, completed?, etc.) provided by Statusable concern

  # ============================================
  # МЕТОД ДЛЯ ЧАТА
  # ============================================
  def has_chat?
    conversation.present?
  end

  def chat_participants
    return [] unless conversation
    [ conversation.asker, conversation.helper ]
  end

  def chat_available_for?(user)
    return false unless in_progress?
    return false unless accepted_offer

    user == self.user || user == accepted_offer.user
  end

  # ============================================
  # СТАТИСТИЧЕСКИЕ МЕТОДЫ
  # ============================================
  # status_counts provided by Statusable concern

  def self.region_counts
    where.not(region: nil).group(:region).count
  end

  def self.category_counts
    group(:category_id).count
  end

  # ============================================
  # МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ДОСТУПОМ
  # ============================================
  def editable_by?(current_user)
    user == current_user && (open? || in_progress?)
  end

  def cancellable_by?(current_user)
    user == current_user && !completed? && !cancelled?
  end

  def can_receive_offers?
    open?
  end

  # ============================================
  # ПЕРЕХОДЫ СТАТУСОВ
  # ============================================
  def mark_in_progress!
    update!(status: "in_progress")
  end

  def mark_completed!
    update!(status: "completed")
  end

  def mark_cancelled!
    update!(status: "cancelled")
  end

  # ============================================
  # МЕТОДЫ ДЛЯ РАБОТЫ С ОТКЛИКАМИ
  # ============================================
  def accepted_offer
    offers.accepted.first
  end

  def pending_offers_count
    # Use counter cache if available, fallback to count
    offers.pending.count
  end

  def total_offers_count
    # Use counter cache column directly for better performance
    offers_count
  end

  # ============================================
  # DISPLAY МЕТОДЫ
  # ============================================
  def location_display
    translated_region = I18n.t("regions.#{region}", default: region) if region.present?
    if city.present? && region.present?
      "#{city}, #{translated_region}"
    elsif region.present?
      translated_region
    elsif city.present?
      city
    else
      I18n.t("requests.location_not_specified")
    end
  end


  # ============================================
  # МЕТОДЫ ДЛЯ УЧРЕЖДЕНИЙ
  # ============================================
  def institution_request?
    institution_id.present?
  end

  def personal_request?
    !institution_request?
  end

  def beneficiary_info
    return nil unless institution_request? && beneficiary_name.present?
    info = beneficiary_name
    info += " (#{beneficiary_age} лет)" if beneficiary_age.present?
    info
  end

  def request_source
    if institution_request?
      institution.name
    else
      user.username
    end
  end
end
