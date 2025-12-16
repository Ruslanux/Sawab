require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get show" do
    # ВАЖНО: Так как в routes.rb стоит param: :username, ключ должен быть username:
    get user_url(username: @user.username, locale: :en)
    assert_response :success
  end
end
