# Provides display-related methods for models with status fields
# Requires the model to define STATUS_COLORS constant mapping status => color
#
# Usage:
#   class MyModel < ApplicationRecord
#     include StatusDisplayable
#
#     STATUS_COLORS = {
#       "pending" => "yellow",
#       "approved" => "green",
#       "rejected" => "red"
#     }.freeze
#   end
#
#   model.status_badge_color  # => "yellow"
#   model.status_label        # => translated status label
#
module StatusDisplayable
  extend ActiveSupport::Concern

  included do
    # Ensure the including class defines STATUS_COLORS
    class_attribute :status_colors, default: {}
  end

  class_methods do
    def define_status_colors(colors)
      self.status_colors = colors.freeze
    end
  end

  # Returns the color for the current status
  # Used for badge styling in views
  def status_badge_color
    self.class.status_colors[status] || "gray"
  end

  # Returns the translated label for the current status
  # Uses I18n with fallback to humanized status
  # Looks for translations at: request_status.open, offer_status.pending, etc.
  def status_label
    model_name = self.class.model_name.singular
    I18n.t("#{model_name}_status.#{status}", default: status&.humanize || "Unknown")
  end
end
