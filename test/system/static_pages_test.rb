# frozen_string_literal: true

require "application_system_test_case"

class StaticPagesTest < ApplicationSystemTestCase
  test "visitor can view about page" do
    visit about_path(locale: :ru)

    assert_selector "h1", text: I18n.t("static_pages.about.title")
    assert_text I18n.t("static_pages.about.what_is_sawab")
    assert_text I18n.t("static_pages.about.need_help_title")
    assert_text I18n.t("static_pages.about.want_help_title")
  end

  test "about page shows join community button for visitors" do
    visit about_path(locale: :ru)

    assert_link I18n.t("static_pages.about.join_community")
  end

  test "about page shows browse requests button for signed in users" do
    sign_in users(:one)

    visit about_path(locale: :ru)

    assert_link I18n.t("static_pages.about.browse_requests")
  end

  test "footer contains about link" do
    visit root_path(locale: :ru)

    within "footer" do
      assert_link I18n.t("footer.about")
    end
  end

  test "footer contains contact email" do
    visit root_path(locale: :ru)

    within "footer" do
      assert_text "info@sawab.kz"
    end
  end

  test "about page works with different locales" do
    # Russian
    visit about_path(locale: :ru)
    assert_text "О проекте Sawab"

    # English
    visit about_path(locale: :en)
    assert_text "About Sawab"

    # Kazakh
    visit about_path(locale: :kk)
    assert_text "Sawab жобасы туралы"
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
