# frozen_string_literal: true

require "test_helper"

class DisputeEscalationJobTest < ActiveJob::TestCase
  setup do
    @admin = users(:admin)
    @user = users(:one)
    @request = requests(:one)
  end

  test "does nothing when no disputed requests" do
    assert_no_difference "Notification.count" do
      DisputeEscalationJob.perform_now
    end
  end

  test "notifies admins about old disputed requests" do
    # Create a disputed request older than threshold
    @request.update!(status: "disputed", updated_at: 4.days.ago)

    assert_difference "Notification.count" do
      DisputeEscalationJob.perform_now
    end

    notification = Notification.last
    assert_equal @admin, notification.recipient
    assert_equal "dispute_created", notification.action
  end

  test "does not notify about recent disputes" do
    # Create a disputed request that is recent
    @request.update!(status: "disputed", updated_at: 1.day.ago)

    assert_no_difference "Notification.count" do
      DisputeEscalationJob.perform_now
    end
  end

  test "does not send duplicate notifications" do
    @request.update!(status: "disputed", updated_at: 4.days.ago)

    # First run creates notification
    assert_difference "Notification.count", 1 do
      DisputeEscalationJob.perform_now
    end

    # Second run should not create duplicate
    assert_no_difference "Notification.count" do
      DisputeEscalationJob.perform_now
    end
  end
end
