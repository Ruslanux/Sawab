require "test_helper"

class RequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_request = requests(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get requests_url(locale: :en)
    assert_response :success
  end

  test "should get new" do
    get new_request_url(locale: :en)
    assert_response :success
  end

  test "should create request" do
    assert_difference("Request.count") do
      post requests_url(locale: :en), params: { request: {
        title: "New Request",
        description: "This is a long description with more than 20 characters",
        category_id: categories(:one).id,
        region: "Aktyubinsk",
        city: "Aktobe"
      } }
    end

    assert_redirected_to request_url(id: Request.last.id, locale: :en)
  end

  test "should show request" do
    get request_url(id: @user_request.id, locale: :en)
    assert_response :success
  end

  test "should get edit" do
    get edit_request_url(id: @user_request.id, locale: :en)
    assert_response :success
  end

  test "should update request" do
    patch request_url(id: @user_request.id, locale: :en), params: { request: {
      title: "Updated Title"
    } }
    assert_redirected_to request_url(id: @user_request.id, locale: :en)
  end

  test "should destroy request" do
    assert_difference("Request.count", -1) do
      delete request_url(id: @user_request.id, locale: :en)
    end

    assert_redirected_to requests_url(locale: :en)
  end

  test "should complete request" do
    # 1. Создаем запрос сразу в нужном статусе, обходя валидации если нужно
    new_request = Request.new(
      title: "Test Request for Completion",
      description: "This is a long enough description for validation to pass",
      category_id: categories(:one).id,
      status: "in_progress", # Сразу ставим нужный статус для теста завершения
      user: @user,
      region: "Aktyubinsk",
      city: "Aktobe"
    )
    new_request.save!(validate: false) # Сохраняем, игнорируя валидации жизненного цикла

    # 2. Создаем оффер сразу принятым
    offer = Offer.new(
      request: new_request,
      user: users(:two),
      message: "I will help you with this task",
      status: "accepted" # Сразу принят
    )
    offer.save!(validate: false) # Сохраняем, игнорируя проверку "request must be open"

    # 3. Теперь база данных в нужном состоянии ("в процессе").
    # Тестируем само действие контроллера:
    patch complete_request_url(id: new_request.id, locale: :en)

    # 4. Проверяем результат
    assert_redirected_to request_url(id: new_request.id, locale: :en)

    new_request.reload
    assert_equal "completed", new_request.status
  end
end
