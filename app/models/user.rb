class User < ApplicationRecord
  include CachedCounter
  include Reportable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable, :lockable

  # Cached counters for notifications and admin messages
  cached_counter :unread_notifications, association: :notifications, scope: :unread
  cached_counter :unread_admin_messages, association: :received_admin_messages, scope: :unread

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :sawab_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :role, inclusion: { in: %w[user admin moderator] }

  # Active Storage attachment
  has_one_attached :profile_picture

  # Profile picture validations
  validate :acceptable_profile_picture

  # Relationships
  has_many :requests, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :reports_created, class_name: "Report", foreign_key: "reporter_id", dependent: :destroy
  has_many :reports_received, class_name: "Report", foreign_key: "reported_user_id", dependent: :nullify
  # reports association is provided by Reportable concern

  # АССОЦИАЦИИ ДЛЯ УВЕДОМЛЕНИЙ
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy

  # АССОЦИАЦИИ ДЛЯ ЧАТА
  has_many :messages, dependent: :destroy
  has_many :conversations_as_asker, class_name: "Conversation", foreign_key: :asker_id, dependent: :destroy
  has_many :conversations_as_helper, class_name: "Conversation", foreign_key: :helper_id, dependent: :destroy

  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges

  # АССОЦИАЦИИ ДЛЯ УЧРЕЖДЕНИЙ
  has_many :institution_members, dependent: :destroy
  has_many :institutions, through: :institution_members

  # АССОЦИАЦИИ ДЛЯ ОТЗЫВОВ
  has_many :reviews_written, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy

  # АССОЦИАЦИИ ДЛЯ АДМИН-СООБЩЕНИЙ
  has_many :sent_admin_messages, class_name: "AdminMessage", foreign_key: "sender_id", dependent: :destroy
  has_many :received_admin_messages, class_name: "AdminMessage", foreign_key: "recipient_id", dependent: :destroy

  after_initialize :set_defaults, if: :new_record?

  def mark_notifications_as_read!
    notifications.unread.update_all(read_at: Time.current)
    clear_unread_notifications_cache
  end

  # НОВЫЕ МЕТОДЫ ДЛЯ ЧАТА
  def conversations
    # Use UNION for better performance than OR
    Conversation.from(
      "(#{conversations_as_asker.to_sql} UNION #{conversations_as_helper.to_sql}) AS conversations"
    )
  end

  def conversation_with(other_user)
    # Use database query instead of loading all conversations into memory
    conversations_as_asker.find_by(helper_id: other_user.id) ||
      conversations_as_helper.find_by(asker_id: other_user.id)
  end


  # Ban check method
  def banned?
    banned_at.present?
  end

  # Method to get avatar URL with different sizes
  def avatar_url(size: :medium)
    return nil unless profile_picture.attached?

    case size
    when :thumb
      profile_picture.variant(resize_to_limit: [ 50, 50 ])
    when :small
      profile_picture.variant(resize_to_limit: [ 100, 100 ])
    when :medium
      profile_picture.variant(resize_to_limit: [ 200, 200 ])
    when :large
      profile_picture.variant(resize_to_limit: [ 400, 400 ])
    else
      profile_picture
    end
  end

  # Role helpers
  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator"
  end

  def staff?
    admin? || moderator?
  end

  # Institution helpers
  def institution_admin?(institution)
    institution_members.exists?(institution: institution, role: :admin)
  end

  def institution_representative?(institution)
    institution_members.exists?(institution: institution, role: [ :admin, :representative ])
  end

  def can_create_institution_request?(institution)
    institution_representative?(institution) && institution.verified?
  end

  def representable_institutions
    institutions.joins(:institution_members)
                .where(institution_members: { role: [ :admin, :representative ] })
                .where(verified: true)
  end

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :moderators, -> { where(role: "moderator") }
  scope :regular_users, -> { where(role: "user") }
  scope :staff, -> { where(role: [ "admin", "moderator" ]) }
  scope :active, -> { where("last_sign_in_at > ?", 30.days.ago) }
  scope :inactive, -> { where("last_sign_in_at < ? OR last_sign_in_at IS NULL", 30.days.ago) }

  private

  def set_defaults
    self.sawab_balance ||= 0
    self.role ||= "user"
  end

  # Validates profile picture file type and size
  def acceptable_profile_picture
    return unless profile_picture.attached?

    # Validate content type
    acceptable_types = [ "image/jpeg", "image/png", "image/gif", "image/webp" ]
    unless acceptable_types.include?(profile_picture.content_type)
      errors.add(:profile_picture, I18n.t("errors.messages.invalid_content_type",
        acceptable: "JPEG, PNG, GIF, WebP"))
    end

    # Validate file size (max 5MB)
    max_size = 5.megabytes
    if profile_picture.byte_size > max_size
      errors.add(:profile_picture, I18n.t("errors.messages.file_size_too_large",
        max_size: "5 MB"))
    end
  end
end
