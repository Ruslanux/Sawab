# frozen_string_literal: true

require "application_system_test_case"

class RequestsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @category = categories(:one)
    @request = requests(:one)
  end

  test "visitor can view requests list" do
    visit requests_path(locale: :ru)

    assert_selector "h1", text: I18n.t("requests.index.title")
  end

  test "visitor can view request details" do
    visit request_path(id: @request.id, locale: :ru)

    assert_text @request.title
    assert_text @request.description
  end

  test "signed in user can create a request" do
    sign_in @user

    visit new_request_path(locale: :ru)

    fill_in "request_title", with: "Need help with moving furniture"
    select @category.name, from: "request_category_id"
    fill_in "request_description", with: "I need someone to help me move a couch and a table to my new apartment."
    select "Almaty", from: "request_region"
    fill_in "request_city", with: "Almaty"

    click_button I18n.t("requests.new.create")

    assert_text "Need help with moving furniture"
  end

  test "user can edit their own request" do
    sign_in @user

    visit edit_request_path(id: @request.id, locale: :ru)

    fill_in "request_title", with: "Updated request title here"
    click_button "Update Request"

    assert_text "Updated request title here"
  end

  test "user sees delete button on their own open request" do
    sign_in @user

    visit request_path(id: @request.id, locale: :ru)

    # Should see the delete button (button_to form) for own request
    assert_button I18n.t("requests.show.delete")
  end

  test "user can filter requests by category" do
    sign_in @user

    visit requests_path(locale: :ru)

    select @category.name, from: "category_id"
    click_button I18n.t("filters.apply_filters")

    assert_current_path(/category_id=#{@category.id}/)
  end

  test "user can search requests" do
    sign_in @user

    visit requests_path(locale: :ru)

    fill_in "q", with: @request.title[0..5]
    click_button I18n.t("filters.apply_filters")

    assert_text @request.title
  end

  test "visitor cannot create request" do
    visit new_request_path(locale: :ru)

    # Should redirect to sign in
    assert_text I18n.t("devise.sessions.new.title")
  end

  test "user cannot edit another user's request" do
    sign_in @other_user

    visit edit_request_path(id: @request.id, locale: :ru)

    # Should be redirected or see an error (Pundit will redirect)
    assert_no_current_path edit_request_path(id: @request.id, locale: :ru)
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
