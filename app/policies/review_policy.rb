class ReviewPolicy < ApplicationPolicy
  # Pundit будет вызывать этот метод для экшена 'new'
  def new?
    create?
  end

  # Pundit будет вызывать этот метод для экшена 'create'
  def create?
    return false unless user.present? # Пользователь должен быть авторизован

    # 1. Запрос должен быть в статусе "completed"
    is_completed = record.request.completed?

    # 2. Пользователь должен быть участником (либо автором, либо хелпером)
    is_participant = (record.request.user_id == user.id || record.request.accepted_offer&.user_id == user.id)

    # 3. У пользователя не должно быть ранее созданных отзывов на этот запрос к этому юзеру
    #    (Контроллер устанавливает reviewer и reviewee ПЕРЕД вызовом authorize)
    has_not_reviewed = !user.reviews_written.exists?(
      request: record.request,
      reviewee: record.reviewee
    )

    # Разрешаем, только если все 3 условия верны
    is_completed && is_participant && has_not_reviewed
  end

  # (P.S. Нам не нужен 'class Scope', так как мы не фильтруем @reviews)
end
