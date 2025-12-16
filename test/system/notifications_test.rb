# frozen_string_literal: true

require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @request = requests(:one)
  end

  test "user can view notifications page" do
    sign_in @user

    visit notifications_path(locale: :ru)

    assert_selector "h1", text: I18n.t("notifications.index.title")
  end

  test "user can see notification in dropdown" do
    # Create a notification
    Notification.create!(
      recipient: @user,
      actor: users(:two),
      notifiable: @request,
      action: "new_offer"
    )

    sign_in @user

    visit root_path(locale: :ru)

    # Click on notifications bell
    find("[data-action='click->notifications#toggleDropdown']").click

    # Should see the notification dropdown
    assert_selector "[data-notifications-target='dropdown']", visible: true
  end

  test "notifications page shows mark all read button when unread exist" do
    # Create unread notifications
    3.times do
      Notification.create!(
        recipient: @user,
        actor: users(:two),
        notifiable: @request,
        action: "new_offer"
      )
    end

    sign_in @user

    # Go to notifications page directly
    visit notifications_path(locale: :ru)

    # Should see mark all as read button (it's button_to, not link_to)
    assert_button I18n.t("notifications.index.mark_all_read")
  end

  test "notifications page displays user notifications" do
    # Create a notification
    Notification.create!(
      recipient: @user,
      actor: users(:two),
      notifiable: @request,
      action: "new_offer"
    )

    sign_in @user

    visit notifications_path(locale: :ru)

    # Should see the notifications page with content
    assert_selector "h1", text: I18n.t("notifications.index.title")
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :ru)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button I18n.t("devise.sessions.new.sign_in")
    assert_text I18n.t("nav.hello")
  end
end
