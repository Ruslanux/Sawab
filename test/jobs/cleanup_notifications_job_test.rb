# frozen_string_literal: true

require "test_helper"

class CleanupNotificationsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @request = requests(:one)
  end

  test "deletes old read notifications" do
    # Create old read notification
    old_notification = Notification.create!(
      recipient: @user,
      actor: @user,
      notifiable: @request,
      action: "new_offer",
      read_at: 31.days.ago,
      created_at: 31.days.ago
    )

    assert_difference "Notification.count", -1 do
      CleanupNotificationsJob.perform_now
    end

    assert_not Notification.exists?(old_notification.id)
  end

  test "does not delete unread notifications" do
    # Create old unread notification
    old_notification = Notification.create!(
      recipient: @user,
      actor: @user,
      notifiable: @request,
      action: "new_offer",
      read_at: nil,
      created_at: 31.days.ago
    )

    assert_no_difference "Notification.count" do
      CleanupNotificationsJob.perform_now
    end

    assert Notification.exists?(old_notification.id)
  end

  test "does not delete recent read notifications" do
    # Create recent read notification
    recent_notification = Notification.create!(
      recipient: @user,
      actor: @user,
      notifiable: @request,
      action: "new_offer",
      read_at: 5.days.ago,
      created_at: 5.days.ago
    )

    assert_no_difference "Notification.count" do
      CleanupNotificationsJob.perform_now
    end

    assert Notification.exists?(recent_notification.id)
  end
end
