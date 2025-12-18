# frozen_string_literal: true

require "application_system_test_case"

class UserProfilesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "visitor can view user profile" do
    visit user_path(username: @user.username, locale: :ru)

    assert_text @user.username
    assert_text I18n.t("users.profile.total_requests")
  end

  test "user can view their own profile" do
    sign_in @user

    visit user_path(username: @user.username, locale: :ru)

    assert_text @user.username
    assert_link I18n.t("users.profile.edit_profile")
  end

  test "user can edit their profile" do
    sign_in @user

    visit edit_profile_path(locale: :ru)

    fill_in "user_username", with: "UpdatedUsername"
    fill_in "user_location", with: "Almaty, Kazakhstan"

    click_button I18n.t("users.edit.update")

    # Wait for redirect to profile page and check for success message or updated name
    assert_current_path user_path(username: "UpdatedUsername", locale: :ru), wait: 5
    assert_text "UpdatedUsername"
  end

  test "user can view leaderboard" do
    sign_in @user

    visit leaderboards_path(locale: :ru)

    # Default view might show all_time, so check for any leaderboard title
    assert_text(/Топ Помощников/)
  end

  test "user profile shows sawab balance" do
    sign_in @user

    visit user_path(username: @user.username, locale: :ru)

    assert_text I18n.t("users.profile.sawab_balance")
  end

  test "user can report another user" do
    sign_in @user

    visit user_path(username: @other_user.username, locale: :ru)

    assert_link I18n.t("users.profile.report_user")
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :ru)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button I18n.t("devise.sessions.new.sign_in")
    assert_text I18n.t("nav.hello")  # Wait for sign in to complete
  end
end
