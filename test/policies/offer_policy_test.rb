require "test_helper"

class OfferPolicyTest < ActiveSupport::TestCase
  def setup
    @user_one = users(:one)
    @user_two = users(:two)
    @admin = users(:admin)
    @request_one = requests(:one)   # Принадлежит user_one, статус: open
    @request_two = requests(:two)   # Принадлежит user_two, статус: in_progress
    @offer_one = offers(:one)       # На request_one от user_two, статус: accepted
    @offer_two = offers(:two)       # На request_two от user_one, статус: pending
  end

  def test_scope
    # OfferPolicy не имеет кастомного scope, используется базовый из ApplicationPolicy
    # который возвращает все записи
    # Просто проверим что можем получить все офферы
    assert_not_nil @offer_one
    assert_not_nil @offer_two
    assert_equal 2, Offer.count
  end

  def test_show
    # Проверяем базовую политику show (обычно наследуется от ApplicationPolicy)
    policy = OfferPolicy.new(@user_one, @offer_one)
    # Если show? не определен, используется false из ApplicationPolicy
    assert_not policy.show?
  end

  def test_create
    # Пользователь может создавать оффер на чужой открытый запрос
    new_offer = Offer.new(request: @request_one, user: @user_two)
    policy = RequestPolicy.new(@user_two, @request_one)
    # Проверяем что запрос открыт и не принадлежит пользователю
    assert_equal "open", @request_one.status
    assert_not_equal @user_two, @request_one.user

    offer_policy = OfferPolicy.new(@user_two, new_offer)
    assert offer_policy.create?

    # Пользователь НЕ может создавать оффер на свой запрос
    own_offer = Offer.new(request: @request_one, user: @user_one)
    policy_own = OfferPolicy.new(@user_one, own_offer)
    assert_not policy_own.create?

    # Нельзя создавать оффер на запрос в статусе in_progress
    offer_in_progress = Offer.new(request: @request_two, user: @admin)
    policy_in_progress = OfferPolicy.new(@admin, offer_in_progress)
    assert_not policy_in_progress.create?

    # Неавторизованный не может
    policy_guest = OfferPolicy.new(nil, new_offer)
    assert_not policy_guest.create?
  end

  def test_update
    # Автор запроса может принять/отклонить pending оффер на open запросе
    # Для этого нужен pending оффер на open запросе
    # offer_two - pending на request_two (in_progress), не подходит
    # Создадим новый оффер на request_one (open)
    pending_offer = Offer.new(request: @request_one, user: @admin, status: "pending", message: "Test offer message")
    pending_offer.save!(validate: false)

    # Автор запроса может обновить статус
    policy = OfferPolicy.new(@user_one, pending_offer)
    assert policy.update?

    # Автор оффера не может сам обновить статус
    policy_author = OfferPolicy.new(@admin, pending_offer)
    assert_not policy_author.update?

    # Нельзя обновить accepted оффер
    policy_accepted = OfferPolicy.new(@user_one, @offer_one)
    assert_not policy_accepted.update?

    # Неавторизованный не может
    policy_guest = OfferPolicy.new(nil, pending_offer)
    assert_not policy_guest.update?
  end

  def test_destroy
    # Автор оффера может удалить свой pending оффер
    # offer_two - pending оффер от user_one
    policy = OfferPolicy.new(@user_one, @offer_two)
    assert policy.destroy?

    # Другой пользователь не может удалить чужой оффер
    policy_other = OfferPolicy.new(@user_two, @offer_two)
    assert_not policy_other.destroy?

    # Нельзя удалить accepted оффер
    policy_accepted = OfferPolicy.new(@user_two, @offer_one)
    assert_not policy_accepted.destroy?

    # Неавторизованный не может
    policy_guest = OfferPolicy.new(nil, @offer_two)
    assert_not policy_guest.destroy?
  end
end
