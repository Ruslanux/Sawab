module TimeFilterable
  extend ActiveSupport::Concern

  included do
    # Time-based filtering scopes
    scope :created_today, -> { where("#{table_name}.created_at >= ?", Time.current.beginning_of_day) }
    scope :created_this_week, -> { where("#{table_name}.created_at >= ?", Time.current.beginning_of_week) }
    scope :created_this_month, -> { where("#{table_name}.created_at >= ?", Time.current.beginning_of_month) }
    scope :all_time, -> { all }

    scope :by_time_period, ->(period) {
      case period&.to_s
      when "today"
        created_today
      when "week"
        created_this_week
      when "month"
        created_this_month
      when "all", nil, ""
        all_time
      else
        all_time
      end
    }

    # Sorting scopes
    scope :recent, -> { order(created_at: :desc) }
    scope :oldest, -> { order(created_at: :asc) }
  end
end
