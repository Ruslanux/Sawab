class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :reported_user, class_name: "User", optional: true
  belongs_to :reportable, polymorphic: true
  belongs_to :resolver, class_name: "User", optional: true

  validates :reason, presence: true, length: { minimum: 10, maximum: 500 }

  # === ПРАВИЛЬНЫЙ СИНТАКСИС для STRING колонок в Rails 7 ===

  enum :status, {
    pending: "pending",
    investigating: "investigating",
    resolved: "resolved",
    dismissed: "dismissed"
  }

  enum :report_type, {
    spam: "spam",
    inappropriate: "inappropriate",
    fraud: "fraud",
    other: "other"
  }

  # Rails автоматически создает:
  # - Scopes: Report.pending, Report.investigating, etc.
  # - Методы проверки: report.pending?, report.investigating?, etc.
  # - Методы изменения: report.pending!, report.investigating!, etc.

  scope :recent, -> { order(created_at: :desc) }

  def resolve!(admin, resolution_note)
    update!(
      status: :resolved,  # используем символ
      resolver: admin,
      resolution_note: resolution_note,
      resolved_at: Time.current
    )
  end

  def dismiss!(admin, resolution_note)
    update!(
      status: :dismissed,  # используем символ
      resolver: admin,
      resolution_note: resolution_note,
      resolved_at: Time.current
    )
  end
end
