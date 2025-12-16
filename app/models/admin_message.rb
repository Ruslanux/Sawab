class AdminMessage < ApplicationRecord
  include Readable

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :body, presence: true, length: { minimum: 5, maximum: 5000 }
end
