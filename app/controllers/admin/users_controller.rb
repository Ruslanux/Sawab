# Admin::UsersController
#
# This controller handles user management in the admin panel.
# SECURITY NOTE: This controller includes intentional mass assignment of sensitive attributes
# (role, sawab_balance) which are protected by:
# 1. Admin-only access via require_admin!
# 2. Additional authorization checks for role modifications via authorize_role_change!
# 3. Separate strong parameter methods for basic vs sensitive attributes
class Admin::UsersController < Admin::BaseController
  load_resource :user, only: %i[show edit update destroy ban unban adjust_sawab remove_avatar]
  before_action :require_admin!, only: %i[ban unban adjust_sawab update destroy]
  before_action :prevent_self_destruction, only: %i[destroy ban]
  before_action :authorize_role_change!, only: :update, if: -> { params.dig(:user, :role).present? }

  def index
    @users = User.includes(:requests, :offers)
                 .order(created_at: :desc)

    @users = filter_by_role(@users)
    @users = filter_by_user_status(@users)
    @users = filter_by_search(@users, :username, :email)
    @users = paginate(@users)
  end

  def show
    @user_requests = @user.requests.includes(:category).order(created_at: :desc).limit(10)
    @user_offers = @user.offers.includes(:request).order(created_at: :desc).limit(10)
    @reports_created = @user.reports_created.order(created_at: :desc).limit(5) if @user.respond_to?(:reports_created)
    @reports_received = @user.reports_received.order(created_at: :desc).limit(5) if @user.respond_to?(:reports_received)
  end

  def edit
  end

  def update
    update_params = basic_user_params

    # Only admins can modify sensitive attributes (role, sawab_balance)
    if current_user.admin? && (params[:user].key?(:role) || params[:user].key?(:sawab_balance))
      update_params = update_params.merge(sensitive_user_params)
    end

    # If password is blank, remove it from params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    username = @user.username

    if @user.destroy
      redirect_to admin_users_path, notice: "User '#{username}' was successfully deleted."
    else
      redirect_to admin_user_path(@user), alert: "Failed to delete user. Please try again."
    end
  end

  def ban
    reason = params[:reason].presence || "No reason provided"

    if @user.update(banned_at: Time.current, banned_reason: reason)
      redirect_to admin_user_path(@user), notice: "User '#{@user.username}' has been banned."
    else
      redirect_to admin_user_path(@user), alert: "Failed to ban user."
    end
  end

  def unban
    if @user.update(banned_at: nil, banned_reason: nil)
      redirect_to admin_user_path(@user), notice: "User '#{@user.username}' has been unbanned."
    else
      redirect_to admin_user_path(@user), alert: "Failed to unban user."
    end
  end

  def adjust_sawab
    amount = params[:amount].to_i

    if amount.zero?
      redirect_to admin_user_path(@user), alert: "Please enter a valid amount."
      return
    end

    @user.transaction do
      new_balance = @user.sawab_balance + amount

      if new_balance >= 0
        @user.update!(sawab_balance: new_balance)
        action = amount > 0 ? "added" : "removed"
        flash[:notice] = "Successfully #{action} #{amount.abs} sawab points. New balance: #{new_balance}"
      else
        flash[:alert] = "Cannot reduce sawab balance below 0"
      end
    end

    redirect_to admin_user_path(@user)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_user_path(@user), alert: "Failed to adjust sawab: #{e.message}"
  end

  def remove_avatar
    if @user.profile_picture.attached?
      @user.profile_picture.purge
      redirect_to edit_admin_user_path(@user), notice: "Profile picture was successfully removed."
    else
      redirect_to edit_admin_user_path(@user), alert: "No profile picture to remove."
    end
  end

  private

  def basic_user_params
    params.require(:user).permit(
      :username, :email, :phone, :location,
      :password, :password_confirmation, :profile_picture
    )
  end

  # Sensitive parameters that require additional authorization
  # SECURITY: This intentionally permits dangerous keys but is protected by:
  # 1. require_admin! before_action
  # 2. authorize_role_change! before_action for role changes
  # 3. Only merged in update action when current_user.admin?
  def sensitive_user_params
    # brakeman:ignore:MassAssignment
    params.require(:user).permit(:role, :sawab_balance)
  end

  def authorize_role_change!
    new_role = params.dig(:user, :role)

    unless current_user.admin?
      redirect_to admin_users_path, alert: "Only admins can change user roles."
      return
    end

    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot change your own role."
      return
    end

    if new_role == "admin" && @user.role != "admin" && params[:confirm_admin_creation] != "true"
      flash[:alert] = "Creating a new admin requires confirmation for security reasons."
      redirect_to edit_admin_user_path(@user)
    end
  end

  def prevent_self_destruction
    return unless @user == current_user

    action = action_name == "destroy" ? "delete" : "ban"
    redirect_to admin_users_path, alert: "You cannot #{action} your own account."
  end
end
