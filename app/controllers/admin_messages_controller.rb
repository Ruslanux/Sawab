class AdminMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_admin_thread_user, only: [ :show ]

  # Инбокс: показывает список диалогов (сгруппированных по админам)
  def index
    admin_ids = User.where(role: [ "admin", "moderator" ]).ids

    # Находим все сообщения, где я либо отправитель, либо получатель (и вторая сторона - админ)
    @messages = AdminMessage.where(recipient: current_user, sender_id: admin_ids)
                            .or(AdminMessage.where(sender: current_user, recipient_id: admin_ids))
                            .order(created_at: :desc)

    # Группируем сообщения в "треды" по ID админа
    @threads = @messages.group_by do |message|
      message.sender_id == current_user.id ? message.recipient_id : message.sender_id
    end

    mark_messages_as_read(@messages)
  end

  # Показывает один "тред" (чат) с конкретным админом
  def show
    # @admin_thread_user был найден before_action

    # Загружаем всю переписку с этим админом
    @messages = AdminMessage.where(recipient: current_user, sender: @admin_thread_user)
                            .or(AdminMessage.where(sender: current_user, recipient: @admin_thread_user))
                            .order(:created_at)

    mark_messages_as_read(@messages)

    @new_message = AdminMessage.new(recipient: @admin_thread_user) # Для формы ответа
  end

  # Создание (Ответ)
  def create
    @admin_message = AdminMessage.new(message_params)
    @admin_message.sender = current_user

    if @admin_message.save
      # Сбрасываем кэш счетчика для получателя (админа)
      @admin_message.recipient.clear_unread_admin_messages_cache

      # TODO: Уведомить админа о новом ответе
      redirect_to admin_message_path(id: @admin_message.recipient_id), notice: "Ваш ответ отправлен."
    else
      # Если не удалось, перезагружаем чат
      @admin_thread_user = User.find(message_params[:recipient_id])
      @messages = AdminMessage.where(recipient: current_user, sender: @admin_thread_user)
                              .or(AdminMessage.where(sender: current_user, recipient: @admin_thread_user))
                              .order(:created_at)
      @new_message = @admin_message # Передаем невалидное сообщение обратно
      flash.now[:alert] = "Сообщение не может быть пустым."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_admin_thread_user
    # ID в URL - это ID админа, с которым мы ведем диалог
    @admin_thread_user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_messages_path, alert: "Диалог не найден."
  end

  def message_params
    params.require(:admin_message).permit(:body, :recipient_id)
  end

  def mark_messages_as_read(messages)
    unread_ids = messages.where(recipient: current_user).unread.pluck(:id)
    return unless unread_ids.any?

    AdminMessage.where(id: unread_ids).update_all(read_at: Time.current)
    current_user.clear_unread_admin_messages_cache
  end
end
