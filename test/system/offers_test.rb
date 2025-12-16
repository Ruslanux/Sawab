# frozen_string_literal: true

require "application_system_test_case"

class OffersTest < ApplicationSystemTestCase
  setup do
    @user_one = users(:one)  # Owner of request:one and request:three
    @user_two = users(:two)  # Owner of request:two
    @open_request = requests(:three)  # Open request by user_one
    @in_progress_request = requests(:two)  # In progress request by user_two
  end

  test "user can make an offer on another user's request" do
    sign_in @user_two

    visit request_path(id: @open_request.id, locale: :ru)

    fill_in "offer_message", with: "I would be happy to help you with this task!"
    click_button I18n.t("requests.show.submit_offer")

    assert_text "I would be happy to help you with this task!"
  end

  test "user cannot make offer on their own request" do
    sign_in @user_one

    visit request_path(id: @open_request.id, locale: :ru)

    # Should see message that user cannot offer on own request
    assert_text I18n.t("requests.show.own_request_msg")
    assert_no_selector "form[action*='offers']"
  end

  test "request owner sees accept button for pending offer" do
    # Create a pending offer
    Offer.create!(
      request: @open_request,
      user: @user_two,
      message: "I can help with this",
      status: "pending"
    )

    sign_in @user_one

    visit request_path(id: @open_request.id, locale: :ru)

    # Should see the accept button
    assert_button I18n.t("requests.show.accept")
  end

  test "request owner sees reject button for pending offer" do
    # Create a pending offer
    Offer.create!(
      request: @open_request,
      user: @user_two,
      message: "I can help with this",
      status: "pending"
    )

    sign_in @user_one

    visit request_path(id: @open_request.id, locale: :ru)

    # Should see the reject button
    assert_button I18n.t("requests.show.reject")
  end

  test "user can view their pending offers" do
    # Create a pending offer
    offer = Offer.create!(
      request: @open_request,
      user: @user_two,
      message: "I can help with this offer",
      status: "pending"
    )

    sign_in @user_two

    # Visit the specific request to see the offer
    visit request_path(id: @open_request.id, locale: :ru)

    # Should see their offer message on the request page
    assert_text "I can help with this offer"
  end

  test "visitor cannot make offer" do
    visit request_path(id: @open_request.id, locale: :ru)

    # Should not see offer form
    assert_no_selector "form[action*='offers']"
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
