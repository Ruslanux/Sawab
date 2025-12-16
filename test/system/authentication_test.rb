# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_user_registration_path(locale: :ru)

    fill_in "user_username", with: "NewTestUser"
    fill_in "user_email", with: "newuser@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    click_button I18n.t("devise.registrations.new.sign_up")

    # Should see confirmation message (Devise confirmable)
    assert_text I18n.t("devise.registrations.signed_up_but_unconfirmed")
  end

  test "user can sign in" do
    user = users(:one)

    visit new_user_session_path(locale: :ru)

    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"

    click_button I18n.t("devise.sessions.new.sign_in")

    assert_text I18n.t("nav.hello")
    assert_text user.username
  end

  test "user can sign out" do
    user = users(:one)

    # Sign in directly
    visit new_user_session_path(locale: :ru)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button I18n.t("devise.sessions.new.sign_in")

    # Verify signed in
    assert_text user.username

    # Now sign out
    click_button I18n.t("nav.sign_out")

    # Should see sign in link after logout
    assert_text I18n.t("nav.sign_in")
  end

  test "user sees error with invalid credentials" do
    visit new_user_session_path(locale: :ru)

    fill_in "user_email", with: "wrong@example.com"
    fill_in "user_password", with: "wrongpassword"

    click_button I18n.t("devise.sessions.new.sign_in")

    assert_text I18n.t("devise.failure.invalid", authentication_keys: "Email")
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
