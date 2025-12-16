# frozen_string_literal: true

require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get about page" do
    get about_path
    assert_response :success
    assert_select "h1", /О проекте Sawab|About Sawab|Sawab жобасы туралы/
  end

  test "should get about page with locale" do
    get about_path(locale: :en)
    assert_response :success
  end

  test "about page is accessible without authentication" do
    get about_path
    assert_response :success
  end
end
