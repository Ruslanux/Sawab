require "test_helper"

class Requests::MarkPendingServiceTest < ActiveSupport::TestCase
  def setup
    I18n.locale = :en
    @user = users(:one)
    @helper = users(:two)
    @category = categories(:one)

    @request = Request.create!(
      title: "Test Request",
      description: "This is a test request for marking pending",
      user: @user,
      category: @category,
      status: "open",
      region: "almaty",
      city: "Almaty"
    )

    @offer = Offer.create!(
      message: "I can help with this",
      user: @helper,
      request: @request,
      status: "pending"
    )

    # Accept the offer which will move request to in_progress
    @offer.accept!
  end

  def teardown
    I18n.locale = I18n.default_locale
  end

  test "marks request as pending completion successfully" do
    service = Requests::MarkPendingService.new(@request)

    assert service.call, "Service should succeed"
    assert service.success?, "Service should report success"
    assert @request.reload.pending_completion?, "Request should be pending completion"
  end

  test "sets pending_completion_at timestamp" do
    service = Requests::MarkPendingService.new(@request)
    service.call

    assert_not_nil @request.reload.pending_completion_at,
      "pending_completion_at should be set"
  end

  test "returns true on success" do
    service = Requests::MarkPendingService.new(@request)

    assert_equal true, service.call
  end

  test "returns false on failure" do
    # Make request invalid
    @request.title = nil
    service = Requests::MarkPendingService.new(@request)

    assert_equal false, service.call
    refute service.success?
  end

  test "populates errors on failure" do
    @request.title = nil
    service = Requests::MarkPendingService.new(@request)

    service.call

    assert_not_empty service.errors, "Service should have errors"
  end

  test "provides error message" do
    @request.title = nil
    service = Requests::MarkPendingService.new(@request)

    service.call

    assert_not_nil service.error_message, "Should provide error message"
  end
end
