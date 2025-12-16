class Admin::AdminMessagesController < Admin::BaseController
  before_action :set_user, only: [ :show ]

  # Список всех диалогов с пользователями
  def index
    admin_ids = User.where(role: [ "admin", "moderator" ]).ids

    # Находим все сообщения, где админ - отправитель или получатель
    messages = AdminMessage.where(recipient_id: admin_ids)
                            .or(AdminMessage.where(sender_id: admin_ids))
                            .order(created_at: :desc)

    # Группируем в "треды" по ID пользователя (не-админа)
    @threads = messages.group_by do |message|
      message.sender_id.in?(admin_ids) ? message.recipient_id : message.sender_id
    end

    # === ИСПРАВЛЕНИЕ ЗДЕСЬ ===
    # Помечаем все непрочитанные сообщения (адресованные ТЕКУЩЕМУ админу) как прочитанные
    unread_ids = messages.where(recipient: current_user).unread.pluck(:id)
    if unread_ids.any?
      AdminMessage.where(id: unread_ids).update_all(read_at: Time.current)
      # Очищаем кэш счетчика
      Rails.cache.delete("user_#{current_user.id}_unread_admin_messages_count")
    end
    # === КОНЕЦ ИСПРАВЛЕНИЯ ===
  end

  # Показывает один "тред" (чат) с конкретным пользователем
  def show
    # @user (User2) был найден before_action

    # Находим ID всех админов
    admin_ids = User.where(role: [ "admin", "moderator" ]).ids

    # Загружаем всю переписку с этим юзером
    @messages = AdminMessage.where(recipient: @user, sender_id: admin_ids)
                            .or(AdminMessage.where(sender: @user, recipient_id: admin_ids))
                            .order(:created_at)

    # Помечаем все непрочитанные сообщения в этом треде как прочитанные
    unread_ids = @messages.where(recipient: current_user).unread.pluck(:id)
    if unread_ids.any?
      AdminMessage.where(id: unread_ids).update_all(read_at: Time.current)
      # Очищаем кэш счетчика
      Rails.cache.delete("user_#{current_user.id}_unread_admin_messages_count")
    end

    @new_message = AdminMessage.new(recipient: @user) # Для формы ответа
  end

  # Отправка сообщения (ИЗ АДМИНКИ)
  def create
    # 1. Извлекаем 'from_user_profile' ПЕРЕД созданием
    from_user_profile = params[:admin_message][:from_user_profile] == "true"

    # 2. Создаем @admin_message только с РАЗРЕШЕННЫМИ параметрами
    @admin_message = AdminMessage.new(message_params)
    @admin_message.sender = current_user # Отправитель - текущий админ

    if @admin_message.save
      # Сбрасываем кэш счетчика для получателя
      Rails.cache.delete("user_#{@admin_message.recipient_id}_unread_admin_messages_count")

      # TODO: Уведомить юзера о новом ответе

      # Редирект обратно в чат с этим юзером
      redirect_to admin_admin_message_path(id: @admin_message.recipient_id), notice: "Сообщение успешно отправлено."
    else
      # Если ошибка, нужно понять, откуда мы пришли
      if from_user_profile
        # Если отправляли со страницы профиля, редирект туда
        redirect_to admin_user_path(id: @admin_message.recipient_id), alert: "Сообщение не может быть пустым."
      else
        # Если отправляли из чата, рендерим 'show'
        set_user_for_show_render
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def set_user
    # ID в URL - это ID пользователя, с которым мы ведем диалог
    @user = User.find(params[:id])
  end

  # Если рендер 'show' не удался, нам нужно снова загрузить переменные
  def set_user_for_show_render
    @user = User.find(message_params[:recipient_id])
    admin_ids = User.where(role: [ "admin", "moderator" ]).ids
    @messages = AdminMessage.where(recipient: @user, sender_id: admin_ids)
                            .or(AdminMessage.where(sender: @user, recipient_id: admin_ids))
                            .order(:created_at)
    @new_message = @admin_message
  end

  def message_params
    # Убираем 'from_user_profile' из permit, т.к. это не атрибут модели
    params.require(:admin_message).permit(:body, :recipient_id)
  end
end
