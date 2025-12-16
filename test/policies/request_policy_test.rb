require "test_helper"

class RequestPolicyTest < ActiveSupport::TestCase
  def setup
    @user_one = users(:one)
    @user_two = users(:two)
    @admin = users(:admin)
    @request_one = requests(:one)   # Принадлежит user_one, статус: open
    @request_two = requests(:two)   # Принадлежит user_two, статус: in_progress
  end

  def test_scope
    # Проверяем scope для авторизованного пользователя
    policy_scope = Pundit.policy_scope(@user_one, Request)
    # Должны видеть: все открытые запросы + все свои запросы
    assert_includes policy_scope, @request_one  # свой open запрос
    assert_includes policy_scope, requests(:three)  # чужой open запрос
    assert_not_includes policy_scope, @request_two  # чужой in_progress запрос

    # Проверяем scope для неавторизованного пользователя
    policy_scope_guest = Pundit.policy_scope(nil, Request)
    # Гости видят только открытые запросы
    assert_includes policy_scope_guest, @request_one
    assert_includes policy_scope_guest, requests(:three)
    assert_not_includes policy_scope_guest, @request_two
  end

  def test_show
    # Все могут видеть запросы
    policy = RequestPolicy.new(@user_one, @request_one)
    assert policy.show?

    policy_guest = RequestPolicy.new(nil, @request_one)
    assert policy_guest.show?
  end

  def test_create
    # Авторизованные пользователи могут создавать запросы
    new_request = Request.new(user: @user_one)
    policy = RequestPolicy.new(@user_one, new_request)
    assert policy.create?

    # Неавторизованные не могут
    policy_guest = RequestPolicy.new(nil, new_request)
    assert_not policy_guest.create?
  end

  def test_update
    # Автор может обновлять свой open запрос
    policy = RequestPolicy.new(@user_one, @request_one)
    assert policy.update?

    # Не автор не может обновлять
    policy_other = RequestPolicy.new(@user_two, @request_one)
    assert_not policy_other.update?

    # Автор не может обновлять запрос в статусе in_progress
    policy_in_progress = RequestPolicy.new(@user_two, @request_two)
    assert_not policy_in_progress.update?

    # Неавторизованный не может
    policy_guest = RequestPolicy.new(nil, @request_one)
    assert_not policy_guest.update?
  end

  def test_destroy
    # Автор может удалять свой open запрос
    policy = RequestPolicy.new(@user_one, @request_one)
    assert policy.destroy?

    # Не автор не может удалять
    policy_other = RequestPolicy.new(@user_two, @request_one)
    assert_not policy_other.destroy?

    # Автор не может удалять запрос в статусе in_progress
    policy_in_progress = RequestPolicy.new(@user_two, @request_two)
    assert_not policy_in_progress.destroy?

    # Неавторизованный не может
    policy_guest = RequestPolicy.new(nil, @request_one)
    assert_not policy_guest.destroy?
  end
end
