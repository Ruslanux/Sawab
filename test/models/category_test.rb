require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def setup
    @category = categories(:one)
  end

  # ============================================
  # VALIDATION TESTS
  # ============================================

  test "should be valid with valid attributes" do
    category = Category.new(name: "Unique Technology Name")
    assert category.valid?
  end

  test "name should be present" do
    @category.name = nil
    assert_not @category.valid?
    assert @category.errors[:name].present?
  end

  test "name should be unique" do
    duplicate_category = @category.dup
    assert_not duplicate_category.valid?
    assert duplicate_category.errors[:name].present?
  end

  # ============================================
  # ASSOCIATION TESTS
  # ============================================

  test "should have many requests" do
    assert_respond_to @category, :requests
  end

  # ============================================
  # CLASS METHOD TESTS
  # ============================================

  test "cached_all should return all categories ordered by name" do
    categories = Category.cached_all
    assert_kind_of Array, categories
    assert categories.all? { |c| c.is_a?(Category) }
  end
end
