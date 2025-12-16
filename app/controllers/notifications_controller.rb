class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :mark_as_read, :destroy ]

  def index
    # Загружаем уведомления БЕЗ includes для polymorphic :notifiable
    @notifications = current_user.notifications
                                 .includes(:actor)  # ← Убрали :notifiable
                                 .recent
                                 .page(params[:page])
                                 .per(20)

    # Отмечаем все уведомления как прочитанные при просмотре страницы
    @unread_ids = @notifications.unread.pluck(:id)
  end

  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_to @notification.url }
      format.json { render json: { success: true } }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    current_user.clear_unread_notifications_cache

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "Все уведомления отмечены как прочитанные" }
      format.json { render json: { success: true } }
    end
  end

  def destroy
    @notification.destroy
    current_user.clear_unread_notifications_cache

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "Уведомление удалено" }
      format.json { head :no_content }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
