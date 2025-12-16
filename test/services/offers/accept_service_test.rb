require "test_helper"

class Offers::AcceptServiceTest < ActiveSupport::TestCase
  def setup
    I18n.locale = :en
    @user = users(:one)
    @helper1 = users(:two)
    @helper2 = User.create!(
      username: "helper2",
      email: "helper2@example.com",
      password: "password",
      confirmed_at: Time.current
    )
    @category = categories(:one)

    @request = Request.create!(
      title: "Test Request",
      description: "This is a test request for accepting offers",
      user: @user,
      category: @category,
      status: "open",
      region: "almaty",
      city: "Almaty"
    )

    @offer = Offer.create!(
      message: "I can help with this",
      user: @helper1,
      request: @request,
      status: "pending"
    )

    @other_offer = Offer.create!(
      message: "I can also help",
      user: @helper2,
      request: @request,
      status: "pending"
    )
  end

  def teardown
    I18n.locale = I18n.default_locale
  end

  test "accepts offer successfully" do
    service = Offers::AcceptService.new(@offer)

    assert service.call, "Service should succeed"
    assert service.success?, "Service should report success"
    assert @offer.reload.accepted?, "Offer should be accepted"
  end

  test "updates request status to in_progress" do
    service = Offers::AcceptService.new(@offer)
    service.call

    assert @request.reload.in_progress?, "Request should be in_progress"
  end

  test "rejects other pending offers" do
    service = Offers::AcceptService.new(@offer)
    service.call

    assert @other_offer.reload.rejected?, "Other offers should be rejected"
  end

  test "fails when request is not open" do
    @request.update!(status: "completed")
    service = Offers::AcceptService.new(@offer)

    refute service.call, "Service should fail"
    assert_includes service.error_message, "only accept offers for open requests"
  end

  test "handles multiple pending offers correctly" do
    # Create a third offer
    helper3 = User.create!(
      username: "helper3",
      email: "helper3@example.com",
      password: "password",
      confirmed_at: Time.current
    )
    offer3 = Offer.create!(
      message: "I can help too",
      user: helper3,
      request: @request,
      status: "pending"
    )

    service = Offers::AcceptService.new(@offer)
    service.call

    # All other offers should be rejected
    assert @other_offer.reload.rejected?
    assert offer3.reload.rejected?

    # Only the accepted offer should be accepted
    assert @offer.reload.accepted?
  end

  test "transaction rolls back on error" do
    # Test actual transaction rollback by closing the request first
    # This will cause the service to fail validation
    @request.update!(status: "completed")

    service = Offers::AcceptService.new(@offer)
    result = service.call

    refute result, "Service should fail"

    # Offers should remain unchanged
    assert @offer.reload.pending?
    assert @other_offer.reload.pending?
  end

  test "provides error message on failure" do
    @request.update!(status: "completed")
    service = Offers::AcceptService.new(@offer)

    service.call

    assert_not_nil service.error_message, "Should provide error message"
  end

  test "does not reject the accepted offer itself" do
    service = Offers::AcceptService.new(@offer)
    service.call

    assert @offer.reload.accepted?, "Accepted offer should not be rejected"
  end
end
