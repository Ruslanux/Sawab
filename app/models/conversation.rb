class Conversation < ApplicationRecord
  belongs_to :request
  belongs_to :asker, class_name: "User"
  belongs_to :helper, class_name: "User"
  has_many :messages, -> { order(created_at: :asc) }, dependent: :destroy

  validates :request_id, uniqueness: true
  validate :participants_must_be_different

  def participant?(user)
    user == asker || user == helper
  end

  def other_participant(user)
    user == asker ? helper : asker
  end

  private

  def participants_must_be_different
    return unless asker_id.present? && helper_id.present?

    errors.add(:helper, "cannot be the same as asker") if asker_id == helper_id
  end
end
