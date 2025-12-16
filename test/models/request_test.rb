require "test_helper"

class RequestTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @category = categories(:one)
    @request = requests(:one)
  end

  # ============================================
  # VALIDATION TESTS
  # ============================================

  test "should be valid with valid attributes" do
    request = Request.new(
      title: "Need help with coding",
      description: "I need help with my Ruby on Rails project",
      user: @user,
      category: @category,
      status: "open",
      region: "almaty",
      city: "Almaty"
    )
    assert request.valid?
  end

  test "title should be present" do
    @request.title = nil
    assert_not @request.valid?
    assert @request.errors[:title].present?
  end

  test "title should have minimum length of 5" do
    @request.title = "ab"
    assert_not @request.valid?
    assert @request.errors[:title].present?
  end

  test "title should have maximum length of 100" do
    @request.title = "a" * 101
    assert_not @request.valid?
    assert @request.errors[:title].present?
  end

  test "description should be present" do
    @request.description = nil
    assert_not @request.valid?
    assert @request.errors[:description].present?
  end

  test "description should have minimum length of 20" do
    @request.description = "short"
    assert_not @request.valid?
    assert @request.errors[:description].present?
  end

  test "category_id should be present" do
    @request.category_id = nil
    assert_not @request.valid?
    assert @request.errors[:category_id].present?
  end

  test "region should be present" do
    @request.region = ""
    assert_not @request.valid?
    assert @request.errors[:region].present?
  end

  test "city should be present" do
    @request.city = ""
    assert_not @request.valid?
    assert @request.errors[:city].present?
  end

  test "status should be valid" do
    valid_statuses = %w[open in_progress completed cancelled pending_completion disputed]
    valid_statuses.each do |status|
      @request.status = status
      assert @request.valid?, "#{status} should be a valid status"
    end
  end

  test "status should reject invalid values" do
    @request.status = "invalid"
    assert_not @request.valid?
  end

  # ============================================
  # ASSOCIATION TESTS
  # ============================================

  test "should belong to user" do
    assert_respond_to @request, :user
  end

  test "should belong to category" do
    assert_respond_to @request, :category
  end

  test "should have many offers" do
    assert_respond_to @request, :offers
  end

  test "should have one conversation" do
    assert_respond_to @request, :conversation
  end

  test "should have many reviews" do
    assert_respond_to @request, :reviews
  end

  # ============================================
  # STATUS HELPER METHOD TESTS
  # ============================================

  test "open? should return true for open requests" do
    @request.status = "open"
    assert @request.open?
  end

  test "open? should return false for non-open requests" do
    @request.status = "completed"
    assert_not @request.open?
  end

  test "in_progress? should return true for in_progress requests" do
    @request.status = "in_progress"
    assert @request.in_progress?
  end

  test "completed? should return true for completed requests" do
    @request.status = "completed"
    assert @request.completed?
  end

  test "cancelled? should return true for cancelled requests" do
    @request.status = "cancelled"
    assert @request.cancelled?
  end

  test "pending_completion? should return true for pending_completion requests" do
    @request.status = "pending_completion"
    assert @request.pending_completion?
  end

  test "disputed? should return true for disputed requests" do
    @request.status = "disputed"
    assert @request.disputed?
  end

  # ============================================
  # SCOPE TESTS
  # ============================================

  test "open_requests scope should return only open requests" do
    @request.update(status: "open")
    open_reqs = Request.open_requests
    assert_includes open_reqs, @request
    assert open_reqs.all? { |r| r.status == "open" }
  end

  test "in_progress scope should return only in_progress requests" do
    @request.update(status: "in_progress")
    in_progress_reqs = Request.in_progress
    assert_includes in_progress_reqs, @request
    assert in_progress_reqs.all? { |r| r.status == "in_progress" }
  end

  test "completed scope should return only completed requests" do
    @request.update(status: "completed")
    completed_reqs = Request.completed
    assert_includes completed_reqs, @request
    assert completed_reqs.all? { |r| r.status == "completed" }
  end

  test "cancelled scope should return only cancelled requests" do
    @request.update(status: "cancelled")
    cancelled_reqs = Request.cancelled
    assert_includes cancelled_reqs, @request
    assert cancelled_reqs.all? { |r| r.status == "cancelled" }
  end

  test "by_category scope should filter by category" do
    filtered = Request.by_category(@category.id)
    assert filtered.all? { |r| r.category_id == @category.id }
  end

  test "by_region scope should filter by region" do
    @request.update(region: "Almaty")
    filtered = Request.by_region("Almaty")
    assert_includes filtered, @request
    assert filtered.all? { |r| r.region == "Almaty" }
  end

  test "by_city scope should filter by city" do
    @request.update(city: "Almaty City")
    filtered = Request.by_city("almaty")
    assert_includes filtered, @request
  end

  test "search scope should find requests by title" do
    @request.update(title: "Unique Search Title Test")
    results = Request.search("Unique")
    assert_includes results, @request
  end

  test "search scope should find requests by description" do
    @request.update(description: "This is a unique description for testing search functionality")
    results = Request.search("unique")
    assert_includes results, @request
  end

  test "recent scope should order by created_at desc" do
    old_request = Request.create!(
      title: "Old Request Title",
      description: "This is old request description for testing",
      user: @user,
      category: @category,
      region: "almaty",
      city: "Almaty",
      created_at: 2.days.ago
    )
    new_request = Request.create!(
      title: "New Request Title",
      description: "This is new request description for testing",
      user: @user,
      category: @category,
      region: "almaty",
      city: "Almaty",
      created_at: 1.hour.ago
    )

    recent = Request.recent
    assert_equal new_request, recent.first
  end

  # ============================================
  # PERMISSION METHOD TESTS
  # ============================================

  test "editable_by? should return true for owner with open request" do
    @request.update(status: "open")
    assert @request.editable_by?(@user)
  end

  test "editable_by? should return true for owner with in_progress request" do
    @request.update(status: "in_progress")
    assert @request.editable_by?(@user)
  end

  test "editable_by? should return false for owner with completed request" do
    @request.update(status: "completed")
    assert_not @request.editable_by?(@user)
  end

  test "editable_by? should return false for non-owner" do
    other_user = users(:two)
    assert_not @request.editable_by?(other_user)
  end

  test "cancellable_by? should return true for owner with open request" do
    @request.update(status: "open")
    assert @request.cancellable_by?(@user)
  end

  test "cancellable_by? should return false for completed request" do
    @request.update(status: "completed")
    assert_not @request.cancellable_by?(@user)
  end

  test "cancellable_by? should return false for cancelled request" do
    @request.update(status: "cancelled")
    assert_not @request.cancellable_by?(@user)
  end

  test "can_receive_offers? should return true for open requests" do
    @request.update(status: "open")
    assert @request.can_receive_offers?
  end

  test "can_receive_offers? should return false for non-open requests" do
    @request.update(status: "completed")
    assert_not @request.can_receive_offers?
  end

  # ============================================
  # STATUS TRANSITION TESTS
  # ============================================

  test "mark_in_progress! should update status to in_progress" do
    @request.update(status: "open")
    @request.mark_in_progress!
    assert_equal "in_progress", @request.status
  end

  test "mark_completed! should update status to completed" do
    @request.update(status: "in_progress")
    @request.mark_completed!
    assert_equal "completed", @request.status
  end

  test "mark_cancelled! should update status to cancelled" do
    @request.update(status: "open")
    @request.mark_cancelled!
    assert_equal "cancelled", @request.status
  end

  # ============================================
  # OFFER METHODS TESTS
  # ============================================

  test "pending_offers_count should return count of pending offers" do
    @request.update(status: "open")
    assert_respond_to @request, :pending_offers_count
    assert_kind_of Integer, @request.pending_offers_count
  end

  test "total_offers_count should return total count of offers" do
    assert_respond_to @request, :total_offers_count
    assert_kind_of Integer, @request.total_offers_count
  end

  test "accepted_offer should return accepted offer if exists" do
    # Create a new request without existing offers
    new_request = Request.create!(
      title: "New Test Request",
      description: "This is a new test request for accepted offer test",
      user: @user,
      category: @category,
      status: "open",
      region: "almaty",
      city: "Almaty"
    )
    helper = users(:two)
    offer = new_request.offers.create!(user: helper, message: "I can help with this task", status: "pending")
    new_request.update(status: "in_progress")
    offer.update(status: "accepted")

    assert_equal offer, new_request.accepted_offer
  end

  # ============================================
  # DISPLAY METHODS TESTS
  # ============================================

  test "location_display should return city and translated region when both present" do
    @request.update(city: "Almaty", region: "almaty")
    translated_region = I18n.t("regions.almaty", default: "almaty")
    assert_equal "Almaty, #{translated_region}", @request.location_display
  end

  # NOTE: Tests for nil city/region removed because NOT NULL constraints
  # now enforce that both region and city must always be present

  test "status_badge_color should return correct color for each status" do
    @request.status = "open"
    assert_equal "blue", @request.status_badge_color

    @request.status = "in_progress"
    assert_equal "yellow", @request.status_badge_color

    @request.status = "completed"
    assert_equal "green", @request.status_badge_color

    @request.status = "cancelled"
    assert_equal "red", @request.status_badge_color
  end

  # ============================================
  # DEPENDENT DESTROY TESTS
  # ============================================

  test "destroying request should destroy associated offers" do
    request = Request.create!(
      title: "Test Request For Destroy",
      description: "This is a test description for destroy test",
      user: @user,
      category: @category,
      status: "open",
      region: "almaty",
      city: "Almaty"
    )
    helper = users(:two)
    request.offers.create!(user: helper, message: "Test offer message here")

    assert_difference "Offer.count", -1 do
      request.destroy
    end
  end
end
