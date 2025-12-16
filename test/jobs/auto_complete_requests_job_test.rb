# frozen_string_literal: true

require "test_helper"

class AutoCompleteRequestsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:two)  # Owner of request:two (in_progress)
    @helper = users(:one)  # Has offer on request:two
    @request = requests(:two)  # in_progress request
    @offer = offers(:two)  # pending offer by user:one on request:two

    # Setup: make the offer accepted so we have an accepted_offer
    @offer.update!(status: "accepted")
  end

  test "does nothing when no pending_completion requests" do
    assert_no_changes -> { @request.reload.status } do
      AutoCompleteRequestsJob.perform_now
    end
  end

  test "auto-completes old pending_completion requests" do
    @request.update!(
      status: "pending_completion",
      pending_completion_at: 8.days.ago
    )

    initial_balance = @helper.sawab_balance

    AutoCompleteRequestsJob.perform_now

    @request.reload
    @helper.reload

    assert_equal "completed", @request.status
    assert_equal initial_balance + 1, @helper.sawab_balance
  end

  test "does not complete recent pending_completion requests" do
    @request.update!(
      status: "pending_completion",
      pending_completion_at: 3.days.ago
    )

    assert_no_changes -> { @request.reload.status } do
      AutoCompleteRequestsJob.perform_now
    end
  end

  test "creates notification for auto-completed request" do
    @request.update!(
      status: "pending_completion",
      pending_completion_at: 8.days.ago
    )

    # CompleteService creates one notification, AutoCompleteJob creates another
    assert_difference "Notification.count", 2 do
      AutoCompleteRequestsJob.perform_now
    end

    # Check that auto_completed notification was created
    notification = Notification.where(action: "request_auto_completed").last
    assert_equal @user, notification.recipient
  end
end
