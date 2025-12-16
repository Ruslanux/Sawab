require "test_helper"

class OffersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)   # Будет автором запроса (Author)
    @helper = users(:two) # Будет автором оффера (Helper)
    @admin = users(:admin) # Дополнительный пользователь для тестов

    @user_request = requests(:one)
    @offer = offers(:one)

    # ГАРАНТИРУЕМ правильное состояние базы данных для Pundit:
    # 1. Запрос принадлежит @user и он открыт
    @user_request.update_columns(user_id: @user.id, status: "open")

    # 2. Оффер принадлежит @helper, относится к этому запросу и он в ожидании
    @offer.update_columns(request_id: @user_request.id, user_id: @helper.id, status: "pending")
  end

  test "should create offer" do
    # Оффер создает третий пользователь (не автор запроса и не тот, у кого уже есть pending offer)
    # Используем @admin, так как у @helper уже есть pending offer на этот запрос
    sign_in @admin

    assert_difference("Offer.count") do
      post request_offers_url(request_id: @user_request.id, locale: :en), params: {
        offer: {
          message: "I can help you with this task. It is long enough."
        }
      }
    end

    assert_redirected_to request_url(id: @user_request.id, locale: :en)
  end

  test "should update offer" do
    # Оффер принимает (обновляет статус) АВТОР запроса
    sign_in @user

    # Отправляем PATCH запрос на обновление статуса
    patch offer_url(id: @offer.id, locale: :en), params: { status: "accepted" }

    # Проверяем, что нас перенаправили на страницу запроса
    assert_redirected_to request_url(id: @user_request.id, locale: :en)

    # Проверяем, что статус действительно изменился
    @offer.reload
    assert_equal "accepted", @offer.status
  end
end
