require "test_helper"

class Requests::CompleteServiceTest < ActiveSupport::TestCase
  def setup
    I18n.locale = :en
    @user = users(:one)
    @helper = users(:two)
    @category = categories(:one)

    @request = Request.create!(
      title: "Test Request",
      description: "This is a test request for completion",
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

  test "completes request successfully" do
    service = Requests::CompleteService.new(@request)

    assert service.call, "Service should succeed"
    assert service.success?, "Service should report success"
    assert @request.reload.completed?, "Request should be completed"
  end

  test "increments helper sawab balance" do
    initial_balance = @helper.sawab_balance
    service = Requests::CompleteService.new(@request)

    service.call

    assert_equal initial_balance + 1, @helper.reload.sawab_balance,
      "Helper's balance should be incremented"
  end

  test "fails when request is already completed" do
    @request.update!(status: "completed")
    service = Requests::CompleteService.new(@request)

    refute service.call, "Service should fail"
    refute service.success?, "Service should report failure"
    assert_not_empty service.errors, "Service should have errors"
  end

  test "fails when request is cancelled" do
    @request.update!(status: "cancelled")
    service = Requests::CompleteService.new(@request)

    refute service.call, "Service should fail"
    assert_includes service.error_message, "already completed or cancelled"
  end

  test "fails when no accepted offer exists" do
    @offer.update!(status: "rejected")
    service = Requests::CompleteService.new(@request)

    refute service.call, "Service should fail"
    assert_includes service.error_message, "no accepted offer found"
  end

  test "works from pending_completion status" do
    @request.update!(status: "pending_completion")
    service = Requests::CompleteService.new(@request)

    assert service.call, "Service should succeed from pending_completion"
    assert @request.reload.completed?
  end

  test "handles transaction rollback on error" do
    @request.update!(status: "in_progress")

    # Remove accepted offer to force failure
    @offer.destroy

    service = Requests::CompleteService.new(@request)
    refute service.call

    # Request should still be in_progress
    assert @request.reload.in_progress?, "Request status should not change on failure"
  end
end
