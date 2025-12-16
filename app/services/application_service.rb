# Base class for all service objects
# Provides common interface for error handling and result checking
#
# Usage:
#   class MyService < ApplicationService
#     def initialize(param)
#       super()
#       @param = param
#     end
#
#     def call
#       return add_error("Invalid param") unless @param.valid?
#       # do work
#       true
#     end
#   end
#
#   service = MyService.new(param)
#   if service.call
#     # success
#   else
#     service.error_message # => "Invalid param"
#   end
#
class ApplicationService
  attr_reader :errors

  def initialize
    @errors = []
  end

  def call
    raise NotImplementedError, "#{self.class}#call must be implemented"
  end

  def success?
    errors.empty?
  end

  def failure?
    !success?
  end

  def error_message
    errors.first
  end

  def error_messages
    errors.join(", ")
  end

  protected

  def add_error(message)
    @errors << message
    false
  end

  def add_errors(messages)
    @errors.concat(Array(messages))
    false
  end

  def with_transaction(&block)
    ApplicationRecord.transaction(&block)
  rescue ActiveRecord::RecordInvalid => e
    add_error(e.record.errors.full_messages.join(", "))
  rescue StandardError => e
    add_error(e.message)
  end
end
