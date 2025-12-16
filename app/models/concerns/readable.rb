module Readable
  extend ActiveSupport::Concern

  included do
    scope :unread, -> { where(read_at: nil) }
    scope :read, -> { where.not(read_at: nil) }
    scope :recent, -> { order(created_at: :desc) }
  end

  def mark_as_read!
    return if read?

    update(read_at: Time.current)
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end
end
