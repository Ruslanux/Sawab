# frozen_string_literal: true

require "application_system_test_case"

class RequestCompletionTest < ApplicationSystemTestCase
  setup do
    @asker = users(:two)  # Owner of request:two (in_progress)
    @helper = users(:one)  # Made offer on request:two
    @request = requests(:two)  # in_progress request

    # Set up the accepted offer
    @offer = offers(:two)
    @offer.update!(status: "accepted")
  end

  test "asker can view in progress request" do
    sign_in @asker

    visit request_path(id: @request.id, locale: :ru)

    # Should see the request details
    assert_text @request.title
    assert_text @request.description

    # Should see complete button for in_progress request
    assert_selector "form[action*='complete']" if @request.in_progress?
  end

  test "helper can view request they offered on" do
    sign_in @helper

    visit request_path(id: @request.id, locale: :ru)

    # Should see the request details
    assert_text @request.title
  end

  test "request shows correct status" do
    sign_in @asker

    visit request_path(id: @request.id, locale: :ru)

    # Should show in_progress status
    assert_text I18n.t("request_status.in_progress")
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
