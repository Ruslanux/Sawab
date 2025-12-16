module Reportable
  extend ActiveSupport::Concern

  included do
    # Polymorphic association for reports
    has_many :reports, as: :reportable, dependent: :destroy
  end

  # Check if this record has been reported
  def reported?
    reports.exists?
  end

  # Count of reports on this record
  def reports_count
    reports.count
  end

  # Count of pending reports
  def pending_reports_count
    reports.where(status: "pending").count
  end

  # Check if user has reported this record
  def reported_by?(user)
    return false unless user
    reports.exists?(reporter_id: user.id)
  end
end
