module Statusable
  extend ActiveSupport::Concern

  included do
    scope :with_status, ->(status) { where(status: status) if status.present? }
  end

  class_methods do
    def status_counts
      group(:status).count
    end

    # Define explicit status check methods for better performance and IDE support
    # Usage in model: define_status_methods %w[open in_progress completed]
    def define_status_methods(statuses)
      statuses.each do |status|
        method_name = "#{status}?"

        define_method(method_name) do
          self.status == status
        end
      end
    end
  end
end
