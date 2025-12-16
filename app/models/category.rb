class Category < ApplicationRecord
  has_many :requests, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { minimum: 2, maximum: 50 }

  scope :ordered, -> { order(:name) }

  def self.cached_all
    Rails.cache.fetch("categories_all", expires_in: 1.hour) do
      ordered.to_a
    end
  end
end
