require "test_helper"

class OfferTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @helper = users(:two)
    @request = requests(:one)
    @request.update(user: @user, status: "open")
    @offer = offers(:one)
  end

  # ============================================
  # VALIDATION TESTS
  # ============================================

  test "should be valid with valid attributes" do
    offer = Offer.new(
      user: @helper,
      request: @request,
      message: "I can help you with this task",
      status: "pending"
    )
    assert offer.valid?
  end

  test "message should be present" do
    @offer.message = nil
    assert_not @offer.valid?
    assert @offer.errors[:message].present?
  end

  test "message should have minimum length of 10" do
    @offer.message = "short"
    assert_not @offer.valid?
    assert @offer.errors[:message].present?
  end

  test "message should have maximum length of 500" do
    @offer.message = "a" * 501
    assert_not @offer.valid?
    assert @offer.errors[:message].present?
  end

  test "status should be valid" do
    valid_statuses = %w[pending accepted rejected]
    valid_statuses.each do |status|
      @offer.status = status
      assert @offer.valid?, "#{status} should be a valid status"
    end
  end

  test "status should reject invalid values" do
    @offer.status = "invalid"
    assert_not @offer.valid?
  end

  test "user cannot offer help on their own request" do
    offer = Offer.new(
      user: @user,  # Same as request owner
      request: @request,
      message: "I can help myself",
      status: "pending"
    )
    assert_not offer.valid?
    assert_includes offer.errors[:user], "cannot offer help on their own request"
  end

  test "request must be open to create offers" do
    @request.update(status: "completed")
    offer = Offer.new(
      user: @helper,
      request: @request,
      message: "I can help with this",
      status: "pending"
    )
    assert_not offer.valid?
    assert_includes offer.errors[:request], "must be open to create offers"
  end

  test "cannot create duplicate pending offer" do
    # Create first offer
    Offer.create!(
      user: @helper,
      request: @request,
      message: "First offer message here",
      status: "pending"
    )

    # Try to create second pending offer
    duplicate_offer = Offer.new(
      user: @helper,
      request: @request,
      message: "Second offer message here",
      status: "pending"
    )
    assert_not duplicate_offer.valid?
    assert_includes duplicate_offer.errors[:base], "You already have a pending offer on this request"
  end

  # ============================================
  # ASSOCIATION TESTS
  # ============================================

  test "should belong to user" do
    assert_respond_to @offer, :user
  end

  test "should belong to request" do
    assert_respond_to @offer, :request
  end

  # ============================================
  # STATUS HELPER METHOD TESTS
  # ============================================

  test "pending? should return true for pending offers" do
    @offer.status = "pending"
    assert @offer.pending?
  end

  test "pending? should return false for non-pending offers" do
    @offer.status = "accepted"
    assert_not @offer.pending?
  end

  test "accepted? should return true for accepted offers" do
    @offer.status = "accepted"
    assert @offer.accepted?
  end

  test "accepted? should return false for non-accepted offers" do
    @offer.status = "pending"
    assert_not @offer.accepted?
  end

  test "rejected? should return true for rejected offers" do
    @offer.status = "rejected"
    assert @offer.rejected?
  end

  test "rejected? should return false for non-rejected offers" do
    @offer.status = "pending"
    assert_not @offer.rejected?
  end

  # ============================================
  # SCOPE TESTS
  # ============================================

  test "pending scope should return only pending offers" do
    @offer.update(status: "pending")
    pending_offers = Offer.pending
    assert_includes pending_offers, @offer
    assert pending_offers.all? { |o| o.status == "pending" }
  end

  test "accepted scope should return only accepted offers" do
    @offer.update(status: "accepted")
    accepted_offers = Offer.accepted
    assert_includes accepted_offers, @offer
    assert accepted_offers.all? { |o| o.status == "accepted" }
  end

  test "rejected scope should return only rejected offers" do
    @offer.update(status: "rejected")
    rejected_offers = Offer.rejected
    assert_includes rejected_offers, @offer
    assert rejected_offers.all? { |o| o.status == "rejected" }
  end

  test "for_user scope should filter by user" do
    filtered = Offer.for_user(@offer.user)
    assert filtered.all? { |o| o.user_id == @offer.user_id }
  end

  # ============================================
  # PERMISSION METHOD TESTS
  # ============================================

  test "editable_by? should return true for offer owner with pending offer" do
    @offer.update(status: "pending")
    assert @offer.editable_by?(@offer.user)
  end

  test "editable_by? should return false for non-owner" do
    assert_not @offer.editable_by?(@user)
  end

  test "editable_by? should return false for accepted offer" do
    @offer.update(status: "accepted")
    assert_not @offer.editable_by?(@offer.user)
  end

  test "acceptable_by? should return true for request owner with pending offer" do
    @offer.update(request: @request, status: "pending")
    assert @offer.acceptable_by?(@user)
  end

  test "acceptable_by? should return false for non-request-owner" do
    assert_not @offer.acceptable_by?(@helper)
  end

  test "acceptable_by? should return false for non-pending offer" do
    @offer.update(status: "accepted")
    assert_not @offer.acceptable_by?(@user)
  end

  test "rejectable_by? should return true for request owner with pending offer" do
    @offer.update(request: @request, status: "pending")
    assert @offer.rejectable_by?(@user)
  end

  test "rejectable_by? should return false for non-request-owner" do
    assert_not @offer.rejectable_by?(@helper)
  end

  test "can_be_deleted_by? should return true for offer owner with pending offer" do
    @offer.update(status: "pending")
    assert @offer.can_be_deleted_by?(@offer.user)
  end

  test "can_be_deleted_by? should return false for non-owner" do
    assert_not @offer.can_be_deleted_by?(@user)
  end

  test "can_be_deleted_by? should return false for accepted offer" do
    @offer.update(status: "accepted")
    assert_not @offer.can_be_deleted_by?(@offer.user)
  end

  # ============================================
  # STATUS TRANSITION TESTS
  # ============================================

  test "accept! should update offer status to accepted" do
    @offer.update(request: @request, user: @helper, status: "pending")
    @offer.accept!

    assert_equal "accepted", @offer.reload.status
  end

  test "accept! should update request status to in_progress" do
    @offer.update(request: @request, user: @helper, status: "pending")
    @offer.accept!

    assert_equal "in_progress", @request.reload.status
  end

  test "accept! should reject all other pending offers" do
    @offer.update(request: @request, user: @helper, status: "pending")

    # Create another pending offer
    other_helper = users(:admin)
    other_offer = @request.offers.create!(
      user: other_helper,
      message: "I can also help with this",
      status: "pending"
    )

    @offer.accept!

    assert_equal "rejected", other_offer.reload.status
  end

  test "reject! should update offer status to rejected" do
    @offer.update(status: "pending")
    @offer.reject!

    assert_equal "rejected", @offer.reload.status
  end

  # ============================================
  # DISPLAY METHOD TESTS
  # ============================================

  test "status_badge_color should return correct color for each status" do
    @offer.status = "pending"
    assert_equal "yellow", @offer.status_badge_color

    @offer.status = "accepted"
    assert_equal "green", @offer.status_badge_color

    @offer.status = "rejected"
    assert_equal "red", @offer.status_badge_color
  end

  test "status_label should return correct label for each status" do
    I18n.with_locale(:ru) do
      @offer.status = "pending"
      assert_equal "Ожидает", @offer.status_label

      @offer.status = "accepted"
      assert_equal "Принято", @offer.status_label

      @offer.status = "rejected"
      assert_equal "Отклонено", @offer.status_label
    end
  end
end
