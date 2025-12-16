class Review < ApplicationRecord
  belongs_to :request
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validates :reviewer_id, uniqueness: {
    scope: %i[request_id reviewee_id],
    message: "has already submitted a review"
  }
  validate :reviewer_is_participant
  validate :reviewee_is_participant

  scope :recent, -> { order(created_at: :desc) }

  private

  def reviewer_is_participant
    return unless request && reviewer

    unless request.user_id == reviewer_id || request.offers.accepted.exists?(user_id: reviewer_id)
      errors.add(:reviewer, "must be a participant in the request")
    end
  end

  def reviewee_is_participant
    return unless request && reviewee

    unless request.user_id == reviewee_id || request.offers.accepted.exists?(user_id: reviewee_id)
      errors.add(:reviewee, "must be a participant in the request")
    end
  end
end
