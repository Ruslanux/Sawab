class Admin::UserBadgesController < Admin::BaseController
  before_action :set_user_badge, only: [ :destroy ]

  # Выдача кастомной награды
  def create
    @user = User.find(params[:user_id])
    @badge = Badge.find(params[:badge_id])

    user_badge = @user.user_badges.new(badge: @badge, acquired_at: Time.current)

    if user_badge.save
      # Отправляем уведомление юзеру о новой награде
      NotificationService.notify_badge_unlocked(@user, @badge, actor: current_user)
      redirect_to admin_user_path(@user), notice: "Badge '#{@badge.name}' awarded to #{@user.username}."
    else
      redirect_to admin_user_path(@user), alert: "Failed to award badge: #{user_badge.errors.full_messages.join(', ')}"
    end
  end

  # Отзыв награды
  def destroy
    user = @user_badge.user
    badge_name = @user_badge.badge.name

    @user_badge.destroy
    redirect_to admin_user_path(user), notice: "Badge '#{badge_name}' revoked from #{user.username}."
  end

  private

  def set_user_badge
    @user_badge = UserBadge.find(params[:id])
  end
end
