# frozen_string_literal: true

class InstitutionMembersController < ApplicationController
  before_action :set_institution
  before_action :set_institution_member, only: [ :update, :destroy ]

  # ============================================
  # INDEX - Список членов учреждения
  # ============================================
  def index
    authorize @institution, :manage_members?

    @members = @institution.institution_members
                          .includes(:user)
                          .order(role: :desc, created_at: :asc)
  end

  # ============================================
  # CREATE - Добавление нового члена
  # ============================================
  def create
    @member = @institution.institution_members.build(member_params)
    authorize @member

    if @member.save
      redirect_to institution_institution_members_path(@institution),
                  notice: t("institution_members.added")
    else
      @members = @institution.institution_members.includes(:user).order(role: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  # ============================================
  # UPDATE - Обновление роли члена
  # ============================================
  def update
    authorize @member

    if @member.update(member_params)
      redirect_to institution_institution_members_path(@institution),
                  notice: t("institution_members.updated")
    else
      @members = @institution.institution_members.includes(:user).order(role: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  # ============================================
  # DESTROY - Удаление члена из учреждения
  # ============================================
  def destroy
    authorize @member

    if can_remove_member?
      @member.destroy
      redirect_to institution_institution_members_path(@institution),
                  notice: t("institution_members.removed")
    else
      redirect_to institution_institution_members_path(@institution),
                  alert: t("institution_members.cannot_remove_last_admin")
    end
  end

  private

  def set_institution
    @institution = Institution.find(params[:institution_id])
  end

  def set_institution_member
    @member = @institution.institution_members.find(params[:id])
  end

  def member_params
    params.require(:institution_member).permit(:user_id, :role, :position)
  end

  def can_remove_member?
    # Нельзя удалить последнего админа
    return true unless @member.role_admin?
    @institution.institution_members.admins.count > 1
  end
end
