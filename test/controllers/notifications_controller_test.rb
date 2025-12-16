require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @notification = notifications(:one)
  end

  test "should get index" do
    get notifications_url(locale: :en)
    assert_response :success
  end

  test "should mark as read" do
    patch mark_as_read_notification_url(@notification, locale: :en)

    # В зависимости от вашей реализации (Turbo Stream или Redirect)
    # Если redirect:
    if response.redirect?
      assert_response :redirect
    else
      assert_response :success
    end

    @notification.reload
    assert_not_nil @notification.read_at
  end
end
