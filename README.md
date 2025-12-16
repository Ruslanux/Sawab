# Sawab

Платформа взаимопомощи, объединяющая людей для добрых дел. Пользователи могут создавать запросы о помощи и предлагать свою поддержку другим.

## О проекте

**Sawab** (араб. "благое дело") — это веб-приложение для организации взаимопомощи. Платформа позволяет:

- Создавать запросы о помощи с описанием ситуации
- Предлагать помощь другим пользователям
- Общаться в реальном времени через встроенный чат
- Получать виртуальные баллы (Sawab) за оказанную помощь
- Оставлять отзывы и оценки
- Зарабатывать значки за достижения

### Особенности

- **Институциональные запросы** — верифицированные организации (детские дома, дома престарелых, благотворительные фонды) могут создавать запросы от имени подопечных
- **Система модерации** — жалобы, предупреждения, блокировки для поддержания качества сообщества
- **Мультиязычность** — поддержка русского, казахского и английского языков
- **Геолокация** — фильтрация запросов по регионам Казахстана

## Технологии

- **Ruby** 3.4.4
- **Rails** 8.0.3
- **PostgreSQL** — основная база данных
- **Hotwire** (Turbo + Stimulus) — интерактивность без SPA
- **Tailwind CSS** — стилизация
- **Action Cable** — WebSocket для реального времени
- **Devise** — аутентификация
- **Pundit** — авторизация
- **Kaminari** — пагинация

## Требования

- Ruby 3.4.4
- PostgreSQL 14+
- Node.js 18+ (для сборки assets)
- Bundler

## Установка

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-username/sawab.git
cd sawab
```

### 2. Установка зависимостей

```bash
bundle install
```

### 3. Настройка базы данных

Создайте файл `config/database.yml` на основе примера или используйте переменные окружения:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Опционально: загрузка тестовых данных
```

### 4. Настройка переменных окружения

Создайте файл `.env` или настройте переменные окружения:

```env
# База данных
DATABASE_URL=postgresql://user:password@localhost/sawab_development

# Devise
DEVISE_SECRET_KEY=your-secret-key

# Action Cable (production)
REDIS_URL=redis://localhost:6379/1
```

## Запуск

### Режим разработки

```bash
bin/dev
```

Эта команда запускает Rails сервер и Tailwind CSS watcher параллельно.

Или отдельно:

```bash
bin/rails server           # Rails сервер на http://localhost:3000
bin/rails tailwindcss:watch  # Компиляция CSS
```

### Консоль

```bash
bin/rails console
```

## Тестирование

```bash
bin/rails test                    # Все тесты
bin/rails test test/models        # Тесты моделей
bin/rails test test/controllers   # Тесты контроллеров
```

## Линтинг

```bash
bin/rubocop        # Проверка стиля кода
bin/rubocop -a     # Автоисправление
bin/brakeman       # Проверка безопасности
```

## Структура проекта

```
app/
├── channels/          # Action Cable каналы (чат, уведомления)
├── controllers/
│   ├── admin/         # Админ-панель
│   └── concerns/      # Общие модули (Filterable, Admin::Filtering)
├── models/
│   └── concerns/      # Общие модули (TimeFilterable, Statusable, Reportable)
├── policies/          # Pundit политики авторизации
├── services/          # Сервисные объекты (Offers::*, Requests::*, NotificationService)
├── views/
│   ├── layouts/       # application, admin
│   └── shared/        # Переиспользуемые компоненты
└── javascript/
    └── controllers/   # Stimulus контроллеры

config/
├── locales/           # Переводы (ru.yml, en.yml, kk.yml)
└── routes.rb          # Маршруты с locale scope
```

## Основные сущности

### Пользователь (User)
- Роли: `user`, `moderator`, `admin`
- Баланс Sawab (виртуальная валюта)
- Значки за достижения

### Запрос (Request)
- Статусы: `open` → `in_progress` → `pending_completion` → `completed`
- Альтернативные: `disputed`, `cancelled`
- Привязка к категории и локации

### Предложение (Offer)
- Статусы: `pending` → `accepted` / `rejected`
- При принятии создаётся Conversation для чата

### Учреждение (Institution)
- Типы: детский дом, дом престарелых, реабилитационный центр, благотворительный фонд
- Требует верификации администратором

## Админ-панель

Доступна по адресу `/admin` для пользователей с ролями `admin` или `moderator`.

Функции:
- Управление пользователями (бан, роли)
- Модерация запросов и предложений
- Рассмотрение жалоб
- Верификация учреждений
- Управление категориями и значками
- Статистика и дашборд

## Локализация

Приложение поддерживает три языка:
- Русский (`ru`) — по умолчанию
- Казахский (`kk`)
- Английский (`en`)

Язык выбирается через URL: `/ru/requests`, `/kk/requests`, `/en/requests`

## Развёртывание

Проект настроен для развёртывания через [Kamal](https://kamal-deploy.org/):

```bash
kamal setup    # Первоначальная настройка
kamal deploy   # Развёртывание
```

### Production база данных

В production используется multi-database setup:
- `sawab_production` — основная БД
- `sawab_production_cache` — Solid Cache
- `sawab_production_queue` — Solid Queue
- `sawab_production_cable` — Solid Cable

## Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для фичи (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
4. Запушьте ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

## Контакты

По вопросам и предложениям создавайте Issue в репозитории.
