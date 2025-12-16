# frozen_string_literal: true

class Admin::InstitutionsController < Admin::BaseController
  before_action :set_institution, only: [ :show, :destroy, :verify, :unverify ]

  # ============================================
  # INDEX - Список всех учреждений
  # ============================================
  def index
    @institutions = Institution.all
    @institutions = filter_by_status(@institutions, :verified) if params[:verified].present?
    @institutions = filter_by_search(@institutions, :name, :address, :city)
    @institutions = @institutions.by_type(params[:institution_type]) if params[:institution_type].present?
    @institutions = @institutions.recent
    @institutions = paginate(@institutions, per_page: 20)

    @pending_count = Institution.unverified.count
    @verified_count = Institution.verified.count
  end

  # ============================================
  # SHOW - Детали учреждения
  # ============================================
  def show
    @members = @institution.institution_members.includes(:user).order(role: :desc)
    @requests = @institution.requests.includes(:user, :category).recent.limit(10)
    @requests_count = @institution.requests.count
  end

  # ============================================
  # DESTROY - Удаление учреждения
  # ============================================
  def destroy
    @institution.destroy
    redirect_to admin_institutions_path, notice: t("admin.institutions.destroyed"), status: :see_other
  end

  # ============================================
  # VERIFY - Верификация учреждения
  # ============================================
  def verify
    @institution.verify!
    # Уведомление админу учреждения
    admin_member = @institution.institution_members.admins.first
    if admin_member
      NotificationService.notify_institution_verified(@institution, admin_member.user)
    end
    redirect_to admin_institution_path(@institution), notice: t("admin.institutions.verified")
  end

  # ============================================
  # UNVERIFY - Отмена верификации учреждения
  # ============================================
  def unverify
    @institution.unverify!
    redirect_to admin_institution_path(@institution), notice: t("admin.institutions.unverified")
  end

  private

  def set_institution
    @institution = Institution.find(params[:id])
  end

  def filter_by_status(scope, field)
    value = params[:verified]
    case value
    when "true", "1"
      scope.verified
    when "false", "0"
      scope.unverified
    else
      scope
    end
  end
end
