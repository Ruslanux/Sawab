# frozen_string_literal: true

require "test_helper"

class InstitutionTest < ActiveSupport::TestCase
  def setup
    @institution = institutions(:one)
    @user = users(:one)
    @user_two = users(:two)
  end

  # == Validations ==
  test "should be valid with all required fields" do
    assert @institution.valid?
  end

  test "should require name" do
    @institution.name = nil
    assert_not @institution.valid?
    assert @institution.errors[:name].any?
  end

  test "should require address" do
    @institution.address = nil
    assert_not @institution.valid?
  end

  test "should require city" do
    @institution.city = nil
    assert_not @institution.valid?
  end

  test "should require region" do
    @institution.region = nil
    assert_not @institution.valid?
  end

  test "should require phone" do
    @institution.phone = nil
    assert_not @institution.valid?
  end

  test "should require director_name" do
    @institution.director_name = nil
    assert_not @institution.valid?
  end

  test "should validate email format when present" do
    @institution.email = "invalid-email"
    assert_not @institution.valid?
    assert @institution.errors[:email].any?
  end

  test "should allow blank email" do
    @institution.email = ""
    assert @institution.valid?
  end

  test "should validate website format when present" do
    @institution.website = "not-a-url"
    assert_not @institution.valid?
  end

  test "should allow blank website" do
    @institution.website = ""
    assert @institution.valid?
  end

  # == Enums ==
  test "should have institution_type enum" do
    assert_equal "children_center", institutions(:one).institution_type
    assert_equal "nursing_home", institutions(:two).institution_type
    assert_equal "care_facility", institutions(:three).institution_type
  end

  test "should respond to institution_type predicates with prefix" do
    assert @institution.institution_type_children_center?
    assert_not @institution.institution_type_nursing_home?
  end

  # == Associations ==
  test "should have many institution_members" do
    assert_respond_to @institution, :institution_members
    assert @institution.institution_members.count >= 1
  end

  test "should have many members through institution_members" do
    assert_respond_to @institution, :members
    assert_includes @institution.members, @user
  end

  test "should have many requests" do
    assert_respond_to @institution, :requests
  end

  # == Scopes ==
  test "verified scope returns only verified institutions" do
    verified = Institution.verified
    assert verified.all?(&:verified?)
    assert_includes verified, institutions(:one)
    assert_not_includes verified, institutions(:two)
  end

  test "unverified scope returns only unverified institutions" do
    unverified = Institution.unverified
    assert unverified.none?(&:verified?)
    assert_includes unverified, institutions(:two)
    assert_not_includes unverified, institutions(:one)
  end

  test "by_type scope filters by institution type" do
    children_centers = Institution.by_type("children_center")
    assert children_centers.all? { |i| i.institution_type == "children_center" }
  end

  test "by_region scope filters by region" do
    almaty_institutions = Institution.by_region("almaty")
    assert almaty_institutions.all? { |i| i.region.downcase == "almaty" }
  end

  test "search scope finds by name" do
    results = Institution.search("Центр")
    assert_includes results, institutions(:one)
  end

  # == Instance Methods ==
  test "verify! sets verified to true and verified_at" do
    institution = institutions(:two)
    assert_not institution.verified?

    institution.verify!

    assert institution.verified?
    assert_not_nil institution.verified_at
  end

  test "unverify! sets verified to false and clears verified_at" do
    assert @institution.verified?

    @institution.unverify!

    assert_not @institution.verified?
    assert_nil @institution.verified_at
  end

  test "admin? returns true for admin members" do
    assert @institution.admin?(@user)
    assert_not @institution.admin?(@user_two)
  end

  test "member? returns true for any member" do
    assert @institution.member?(@user)
    assert @institution.member?(@user_two)
  end

  test "representative? returns true for admin and representative roles" do
    assert @institution.representative?(@user)
    assert @institution.representative?(@user_two)
  end

  test "full_address returns combined address with translated region" do
    translated_region = I18n.t("regions.#{@institution.region}", default: @institution.region)
    expected = "#{@institution.address}, #{@institution.city}, #{translated_region}"
    assert_equal expected, @institution.full_address
  end

  test "contact_info returns phone, email, and website" do
    info = @institution.contact_info
    assert_includes info, @institution.phone
    assert_includes info, @institution.email
    assert_includes info, @institution.website
  end

  # == Class Methods ==
  test "filter_by applies multiple filters" do
    results = Institution.filter_by(
      institution_type: "children_center",
      verified_only: "true"
    )

    assert results.all?(&:verified?)
    assert results.all? { |i| i.institution_type == "children_center" }
  end
end
