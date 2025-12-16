ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  # Подключаем хелперы Devise для integration тестов
  include Devise::Test::IntegrationHelpers

  # Эта настройка критически важна для маршрутов с (:locale)
  # Она автоматически добавляет locale ко всем запросам в тестах
  def default_url_options
    { locale: I18n.default_locale }
  end

  # Настройка Warden для тестов
  def setup
    super
    Warden.test_mode!
  end

  # Очистка Warden после каждого теста
  def teardown
    super
    Warden.test_reset!
  end
end
