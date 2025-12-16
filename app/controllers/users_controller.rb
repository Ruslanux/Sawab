class UsersController < ApplicationController
  # Просмотр профиля доступен всем
  skip_before_action :authenticate_user!, only: [ :show ]

  before_action :set_user, only: [ :show ]
  before_action :set_current_user, only: [ :edit, :update, :destroy ]
  before_action :authenticate_user!, only: [ :edit, :update, :remove_avatar, :destroy ]

  # Public profile page - /users/:username
  def show
    # User is set by before_action
    # Загружаем запросы и офферы пользователя для отображения в профиле
    @user_requests = @user.requests.order(created_at: :desc).limit(10) # Последние 10 запросов
    @user_offers = @user.offers.includes(:request).order(created_at: :desc).limit(10) # Последние 10 предложений

    # Загружаем награды и отзывы
    @user_badges = @user.user_badges.includes(:badge).order(acquired_at: :desc)
    @user_reviews_received = @user.reviews_received.includes(:reviewer, :request).recent.limit(10)
  end

  # Edit own profile - /profile/edit
  def edit
    # Current user is set by before_action
  end

  # Update own profile
  def update
    # Remove password fields if blank
    update_params = user_params

    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to user_path(@user.username), notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Remove own avatar
  def remove_avatar
    if current_user.profile_picture.attached?
      current_user.profile_picture.purge
      redirect_to edit_profile_path, notice: "Profile picture was successfully removed."
    else
      redirect_to edit_profile_path, alert: "No profile picture to remove."
    end
  end

  # Delete own account
  def destroy
    # Prevent admins from accidentally deleting themselves if they're the only admin
    if @user.admin? && User.where(role: "admin").count == 1
      redirect_to edit_profile_path, alert: t("users.destroy.last_admin_error")
      return
    end

    # Sign out and destroy the user
    sign_out @user
    @user.destroy

    redirect_to root_path, notice: t("users.destroy.success")
  end

  private

  def set_user
    # Ищем пользователя по username. Используем find_by! чтобы получить 404, если не найден
    @user = User.find_by!(username: params[:username])
  end

  def set_current_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(
      :username,
      :email,
      :phone,
      :location,
      :password,
      :password_confirmation,
      :profile_picture
    )
  end
end
