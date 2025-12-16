require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  # ============================================
  # VALIDATION TESTS
  # ============================================

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "username should be present" do
    @user.username = nil
    assert_not @user.valid?
    assert @user.errors[:username].present?
  end

  test "username should be unique (case insensitive)" do
    duplicate_user = @user.dup
    duplicate_user.email = "different@example.com"
    duplicate_user.username = @user.username.upcase
    duplicate_user.save
    assert_not duplicate_user.valid?
  end

  test "email should be present" do
    @user.email = nil
    assert_not @user.valid?
  end

  test "sawab_balance should be non-negative" do
    @user.sawab_balance = -1
    assert_not @user.valid?
    assert @user.errors[:sawab_balance].present?
  end

  test "sawab_balance should accept zero" do
    @user.sawab_balance = 0
    assert @user.valid?
  end

  test "sawab_balance should accept positive numbers" do
    @user.sawab_balance = 100
    assert @user.valid?
  end

  test "role should be valid" do
    valid_roles = %w[user admin moderator]
    valid_roles.each do |role|
      @user.role = role
      assert @user.valid?, "#{role} should be a valid role"
    end
  end

  test "role should reject invalid values" do
    @user.role = "invalid"
    assert_not @user.valid?
  end

  # ============================================
  # DEFAULT VALUE TESTS
  # ============================================

  test "new user should have default sawab_balance of 0" do
    new_user = User.new(username: "newuser", email: "new@example.com", password: "password123")
    assert_equal 0, new_user.sawab_balance
  end

  test "new user should have default role of user" do
    new_user = User.new(username: "newuser", email: "new@example.com", password: "password123")
    assert_equal "user", new_user.role
  end

  # ============================================
  # ASSOCIATION TESTS
  # ============================================

  test "should have many requests" do
    assert_respond_to @user, :requests
  end

  test "should have many offers" do
    assert_respond_to @user, :offers
  end

  test "should have many notifications" do
    assert_respond_to @user, :notifications
  end

  test "should have many conversations_as_asker" do
    assert_respond_to @user, :conversations_as_asker
  end

  test "should have many conversations_as_helper" do
    assert_respond_to @user, :conversations_as_helper
  end

  test "should have many badges through user_badges" do
    assert_respond_to @user, :badges
  end

  test "should have many reviews_written" do
    assert_respond_to @user, :reviews_written
  end

  test "should have many reviews_received" do
    assert_respond_to @user, :reviews_received
  end

  # ============================================
  # ROLE METHOD TESTS
  # ============================================

  test "admin? should return true for admin users" do
    @user.role = "admin"
    assert @user.admin?
  end

  test "admin? should return false for non-admin users" do
    @user.role = "user"
    assert_not @user.admin?
  end

  test "moderator? should return true for moderator users" do
    @user.role = "moderator"
    assert @user.moderator?
  end

  test "moderator? should return false for non-moderator users" do
    @user.role = "user"
    assert_not @user.moderator?
  end

  test "staff? should return true for admin" do
    @user.role = "admin"
    assert @user.staff?
  end

  test "staff? should return true for moderator" do
    @user.role = "moderator"
    assert @user.staff?
  end

  test "staff? should return false for regular user" do
    @user.role = "user"
    assert_not @user.staff?
  end

  # ============================================
  # BAN METHOD TESTS
  # ============================================

  test "banned? should return false when not banned" do
    @user.banned_at = nil
    assert_not @user.banned?
  end

  test "banned? should return true when banned" do
    @user.banned_at = Time.current
    assert @user.banned?
  end

  # ============================================
  # SCOPE TESTS
  # ============================================

  test "admins scope should return only admin users" do
    admin = users(:admin)
    admin.update(role: "admin")

    admins = User.admins
    assert_includes admins, admin
    assert admins.all? { |u| u.role == "admin" }
  end

  test "moderators scope should return only moderator users" do
    @user.update(role: "moderator")

    moderators = User.moderators
    assert_includes moderators, @user
    assert moderators.all? { |u| u.role == "moderator" }
  end

  test "regular_users scope should return only regular users" do
    @user.update(role: "user")

    regular = User.regular_users
    assert_includes regular, @user
    assert regular.all? { |u| u.role == "user" }
  end

  test "staff scope should return admins and moderators" do
    admin = users(:admin)
    admin.update(role: "admin")
    @user.update(role: "moderator")

    staff = User.staff
    assert_includes staff, admin
    assert_includes staff, @user
    assert staff.all? { |u| u.role.in?([ "admin", "moderator" ]) }
  end

  # ============================================
  # CUSTOM METHOD TESTS
  # ============================================

  test "conversations should return all conversations where user is participant" do
    assert_respond_to @user, :conversations
  end

  test "unread_notifications_count should return count of unread notifications" do
    assert_respond_to @user, :unread_notifications_count
    assert_kind_of Integer, @user.unread_notifications_count
  end

  test "unread_admin_messages_count should return count of unread admin messages" do
    assert_respond_to @user, :unread_admin_messages_count
    assert_kind_of Integer, @user.unread_admin_messages_count
  end

  test "avatar_url should return nil when no profile picture attached" do
    @user.profile_picture.purge if @user.profile_picture.attached?
    assert_nil @user.avatar_url
  end

  # ============================================
  # DEPENDENT DESTROY TESTS
  # ============================================

  test "destroying user should destroy associated requests" do
    user = User.create!(username: "testuser", email: "test@example.com", password: "password123", confirmed_at: Time.current)
    category = categories(:one)
    user.requests.create!(title: "Test Request", description: "Test description for request", category: category, region: "almaty", city: "Almaty")

    assert_difference "Request.count", -1 do
      user.destroy
    end
  end

  test "destroying user should destroy associated offers" do
    user = User.create!(username: "testuser", email: "test@example.com", password: "password123", confirmed_at: Time.current)
    request = requests(:one)
    request.update(status: "open")
    user.offers.create!(request: request, message: "Test offer message here")

    assert_difference "Offer.count", -1 do
      user.destroy
    end
  end
end
