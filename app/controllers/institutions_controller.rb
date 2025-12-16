# frozen_string_literal: true

class InstitutionsController < ApplicationController
  include Filterable

  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_institution, only: [ :show, :edit, :update, :destroy, :requests ]

  # ============================================
  # INDEX - Список всех верифицированных учреждений
  # ============================================
  def index
    @institutions = Institution.verified
                               .filter_by(filter_params)
                               .recent
                               .page(params[:page])
                               .per(12)

    @institution_types = Institution.institution_types.keys
  end

  # ============================================
  # SHOW - Профиль учреждения
  # ============================================
  def show
    authorize @institution

    @requests = @institution.requests
                            .open_requests
                            .with_associations
                            .page(params[:page])
                            .per(10)

    @members = @institution.institution_members
                          .includes(:user)
                          .order(role: :desc)
  end

  # ============================================
  # NEW - Форма создания учреждения
  # ============================================
  def new
    @institution = Institution.new
    authorize @institution
  end

  # ============================================
  # CREATE - Создание нового учреждения
  # ============================================
  def create
    @institution = Institution.new(institution_params)
    authorize @institution

    creator_position = params[:institution][:creator_position]

    ApplicationRecord.transaction do
      if @institution.save
        # Создаем запись о членстве как admin
        @institution.institution_members.create!(
          user: current_user,
          role: :admin,
          position: creator_position
        )

        # Уведомляем админов о новом учреждении (вне транзакции)
        NotificationService.notify_admins_new_institution(@institution, current_user)

        redirect_to @institution, notice: t("institutions.created_pending_verification")
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  # ============================================
  # EDIT - Форма редактирования учреждения
  # ============================================
  def edit
    authorize @institution
  end

  # ============================================
  # UPDATE - Обновление учреждения
  # ============================================
  def update
    authorize @institution

    if @institution.update(institution_params)
      redirect_to @institution, notice: t("institutions.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ============================================
  # DESTROY - Удаление учреждения
  # ============================================
  def destroy
    authorize @institution
    @institution.destroy
    redirect_to institutions_path, notice: t("institutions.destroyed"), status: :see_other
  end

  # ============================================
  # REQUESTS - Запросы от учреждения
  # ============================================
  def requests
    authorize @institution, :show?

    @requests = @institution.requests
                            .with_associations
                            .recent
                            .page(params[:page])
                            .per(20)
  end

  # ============================================
  # MY_INSTITUTIONS - Учреждения пользователя
  # ============================================
  def my_institutions
    @institutions = current_user.institutions
                               .includes(:institution_members)
                               .order(created_at: :desc)
  end

  private

  def set_institution
    @institution = Institution.find(params[:id])
  end

  def institution_params
    params.require(:institution).permit(
      :name, :institution_type, :address, :city, :region,
      :phone, :email, :director_name, :description, :website
    )
  end

  def filter_params
    params.permit(:institution_type, :region, :city, :q, :verified_only)
  end
end
