# Руководство по аутентификации Sawab

Это руководство описывает настройку аутентификации: регистрация, вход, подтверждение email, восстановление пароля и OAuth (Google).

## Содержание

1. [Обзор системы аутентификации](#обзор-системы-аутентификации)
2. [Настройка Email (Gmail SMTP)](#настройка-email-gmail-smtp)
3. [Настройка Email Forwarding (Cloudflare)](#настройка-email-forwarding-cloudflare)
4. [Настройка Google OAuth](#настройка-google-oauth)
5. [GitHub Secrets](#github-secrets)
6. [Отладка и решение проблем](#отладка-и-решение-проблем)

---

## Обзор системы аутентификации

### Используемые технологии

- **Devise** - аутентификация пользователей
- **OmniAuth** - OAuth провайдеры (Google)
- **Action Mailer** - отправка email
- **Gmail SMTP** - почтовый сервер (бесплатно, 500 писем/день)

### Devise модули

Приложение использует следующие модули Devise:

```ruby
# app/models/user.rb
devise :database_authenticatable, :registerable, :recoverable,
       :rememberable, :validatable, :trackable, :confirmable,
       :lockable, :omniauthable, omniauth_providers: [:google_oauth2]
```

| Модуль | Описание |
|--------|----------|
| `database_authenticatable` | Хранение пароля в БД |
| `registerable` | Регистрация пользователей |
| `recoverable` | Восстановление пароля |
| `rememberable` | "Запомнить меня" |
| `validatable` | Валидация email и пароля |
| `trackable` | Отслеживание входов (IP, время) |
| `confirmable` | Подтверждение email |
| `lockable` | Блокировка после неудачных попыток |
| `omniauthable` | OAuth провайдеры |

### Функции аутентификации

- **Регистрация**: email + пароль или Google OAuth
- **Подтверждение email**: обязательно для email-регистрации, не требуется для OAuth
- **Вход**: email/пароль или Google OAuth
- **Восстановление пароля**: по email
- **Блокировка**: 5 неудачных попыток = блокировка на 1 час

---

## Настройка Email (Gmail SMTP)

Gmail SMTP позволяет отправлять до 500 писем в день бесплатно.

### Шаг 1: Включить двухфакторную аутентификацию

1. Откройте [myaccount.google.com/security](https://myaccount.google.com/security)
2. Найдите **"2-Step Verification"** (Двухэтапная аутентификация)
3. Включите, если выключена

### Шаг 2: Создать App Password

1. Перейдите в [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. Выберите:
   - **App**: Mail
   - **Device**: Other (введите "Sawab")
3. Нажмите **Generate**
4. **Скопируйте пароль** (16 символов без пробелов, например: `suymgjvotlbrccbw`)

> **Важно**: Пароль показывается только один раз! Сохраните его.

### Шаг 3: Конфигурация Rails

#### config/environments/production.rb

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
  port: ENV.fetch("SMTP_PORT", 587),
  domain: ENV.fetch("APP_HOST", "sawabapp.org"),
  user_name: ENV["SMTP_USERNAME"],
  password: ENV["SMTP_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = {
  host: ENV.fetch("APP_HOST", "sawabapp.org"),
  protocol: "https"
}
```

#### config/deploy.yml (Kamal)

```yaml
env:
  secret:
    - SMTP_USERNAME
    - SMTP_PASSWORD
  clear:
    SMTP_ADDRESS: smtp.gmail.com
    SMTP_PORT: 587
    MAILER_SENDER: "Sawab <your-email@gmail.com>"
```

#### .kamal/secrets

```bash
SMTP_USERNAME=$SMTP_USERNAME
SMTP_PASSWORD=$SMTP_PASSWORD
```

### Шаг 4: Добавить секреты в GitHub

1. GitHub Repository → **Settings** → **Secrets and variables** → **Actions**
2. Добавьте:
   - `SMTP_USERNAME`: ваш Gmail (например: `zhubanov1090@gmail.com`)
   - `SMTP_PASSWORD`: App Password без пробелов (например: `suymgjvotlbrccbw`)

---

## Настройка Email Forwarding (Cloudflare)

Для красивого email типа `info@sawabapp.org` можно использовать Cloudflare Email Routing.

### Шаг 1: Включить Email Routing

1. Откройте [dash.cloudflare.com](https://dash.cloudflare.com)
2. Выберите ваш домен
3. Перейдите в **Email** → **Email Routing**
4. Нажмите **Get started**

### Шаг 2: Добавить DNS записи

Cloudflare автоматически добавит MX записи. Подтвердите.

### Шаг 3: Подтвердить email получателя

1. В **Destination addresses** добавьте email, куда пересылать
2. Перейдите по ссылке в письме подтверждения

### Шаг 4: Создать правило маршрутизации

1. В **Email Routing** → **Routing rules**
2. **Create address**:
   - Custom address: `info`
   - Destination: ваш Gmail
3. Теперь `info@sawabapp.org` будет пересылаться на ваш Gmail

---

## Настройка Google OAuth

Google OAuth позволяет пользователям входить через Google аккаунт.

### Шаг 1: Создать проект в Google Cloud Console

1. Откройте [console.cloud.google.com](https://console.cloud.google.com)
2. Создайте новый проект или выберите существующий
3. Назовите проект (например: "Sawab")

### Шаг 2: Настроить OAuth Consent Screen

1. Перейдите в **APIs & Services** → **OAuth consent screen**
2. Выберите **External** (для всех пользователей)
3. Заполните:
   - **App name**: Sawab
   - **User support email**: ваш email
   - **App logo**: (опционально)
   - **App domain**: `https://sawabapp.org`
   - **Developer contact**: ваш email
4. **Scopes**: добавьте `email` и `profile`
5. **Test users**: (только для Testing режима) добавьте email тестировщиков
6. **Publishing status**:
   - **Testing**: только добавленные test users могут входить
   - **In production**: все пользователи могут входить (рекомендуется)

### Шаг 3: Создать OAuth Client ID

1. Перейдите в **APIs & Services** → **Credentials**
2. **Create Credentials** → **OAuth client ID**
3. Настройки:
   - **Application type**: Web application
   - **Name**: Sawab Web Client
   - **Authorized JavaScript origins**: `https://sawabapp.org`
   - **Authorized redirect URIs**: `https://sawabapp.org/users/auth/google_oauth2/callback`
4. Сохраните **Client ID** и **Client Secret**

> **Важно**: Redirect URI должен точно совпадать!

### Шаг 4: Конфигурация Rails

#### Gemfile

```ruby
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
```

#### config/initializers/devise.rb

```ruby
if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  config.omniauth :google_oauth2,
                  ENV["GOOGLE_CLIENT_ID"],
                  ENV["GOOGLE_CLIENT_SECRET"],
                  {
                    scope: "email,profile",
                    prompt: "select_account",
                    image_aspect_ratio: "square",
                    image_size: 200
                  }
end
```

#### config/initializers/omniauth.rb

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods = [:post, :get]
  OmniAuth.config.silence_get_warning = true

  OmniAuth.config.full_host = lambda do |env|
    scheme = env["rack.url_scheme"]
    local_host = env["HTTP_HOST"]
    "#{scheme}://#{local_host}"
  end
end
```

#### config/initializers/content_security_policy.rb

```ruby
# Разрешить form-action на Google для OAuth
policy.form_action :self, "https://accounts.google.com"
```

#### app/models/user.rb

```ruby
devise :omniauthable, omniauth_providers: [:google_oauth2]

def self.from_omniauth(auth)
  where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20]
    user.username = generate_unique_username(auth.info.name || auth.info.email.split("@").first)
    user.avatar_url = auth.info.image
    user.confirmed_at = Time.current # OAuth пользователи не требуют подтверждения email
  end
end
```

#### config/routes.rb

```ruby
# OmniAuth callbacks ДОЛЖНЫ быть вне locale scope
devise_for :users, only: :omniauth_callbacks,
           controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

scope "(:locale)", locale: /en|kk|ru/ do
  devise_for :users, skip: :omniauth_callbacks
  # ... остальные routes
end
```

#### app/controllers/users/omniauth_callbacks_controller.rb

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    handle_auth("Google")
  end

  def failure
    redirect_to root_path, alert: t("devise.omniauth_callbacks.failure", reason: failure_message)
  end

  private

  def handle_auth(provider)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = t("devise.omniauth_callbacks.success", kind: provider)
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.oauth_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
```

### Шаг 5: Миграция базы данных

```ruby
# db/migrate/xxx_add_omniauth_to_users.rb
class AddOmniauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string
    add_index :users, [:provider, :uid], unique: true
  end
end
```

### Шаг 6: Кнопка Google в views

```erb
<%# app/views/devise/sessions/new.html.erb %>
<% if devise_mapping.omniauthable? && resource_class.omniauth_providers.any? %>
  <div class="mt-6">
    <% resource_class.omniauth_providers.each do |provider| %>
      <%= button_to omniauth_authorize_path(resource_name, provider),
          method: :post,
          data: { turbo: false },
          class: "..." do %>
        <% if provider == :google_oauth2 %>
          <svg><!-- Google icon --></svg>
          <span>Google</span>
        <% end %>
      <% end %>
    <% end %>
  </div>
<% end %>
```

### Шаг 7: config/deploy.yml

```yaml
env:
  secret:
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET
```

### Шаг 8: .kamal/secrets

```bash
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
```

---

## GitHub Secrets

Полный список секретов для аутентификации:

| Secret | Описание | Пример |
|--------|----------|--------|
| `SMTP_USERNAME` | Gmail адрес | `zhubanov1090@gmail.com` |
| `SMTP_PASSWORD` | Gmail App Password (без пробелов) | `suymgjvotlbrccbw` |
| `GOOGLE_CLIENT_ID` | OAuth Client ID | `419526895354-xxx.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | OAuth Client Secret | `GOCSPX-xxx` |

### Добавление секретов

```bash
# Через GitHub CLI
gh secret set SMTP_USERNAME --body "your-email@gmail.com"
gh secret set SMTP_PASSWORD --body "yourapppassword"
gh secret set GOOGLE_CLIENT_ID --body "your-client-id"
gh secret set GOOGLE_CLIENT_SECRET --body "your-client-secret"
```

---

## Отладка и решение проблем

### Email не отправляется

#### Проверка SMTP настроек

```bash
# В Rails console на сервере
kamal console

# Проверить настройки
ActionMailer::Base.smtp_settings

# Отправить тестовое письмо
UserMailer.with(user: User.first).confirmation_instructions.deliver_now
```

#### Частые ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Net::SMTPAuthenticationError 535-5.7.8` | Неверный пароль | Проверьте App Password без пробелов |
| `Net::SMTPAuthenticationError 534-5.7.9` | 2FA не включена | Включите 2FA в Google |
| `Errno::ECONNREFUSED` | Неверный SMTP сервер | Проверьте SMTP_ADDRESS |

### Google OAuth не работает

#### Кнопка не реагирует на клик

**Причина**: CSP блокирует form-action

**Решение**: Добавьте в `content_security_policy.rb`:
```ruby
policy.form_action :self, "https://accounts.google.com"
```

#### Ошибка "Csrf detected"

**Причина**: OmniAuth CSRF защита

**Решение**: Создайте `config/initializers/omniauth.rb`:
```ruby
OmniAuth.config.allowed_request_methods = [:post, :get]
```

#### Ошибка "redirect_uri_mismatch"

**Причина**: Redirect URI в Google Console не совпадает

**Решение**: Проверьте точное совпадение:
- В Google Console: `https://sawabapp.org/users/auth/google_oauth2/callback`
- Без trailing slash!
- С https!

#### Ошибка "Access blocked: App not verified"

**Причина**: Приложение в режиме Testing

**Решение**:
1. Добавьте email в Test Users, или
2. Опубликуйте приложение: OAuth consent screen → **PUBLISH APP**

### Проверка логов

```bash
# На сервере
ssh root@YOUR_SERVER_IP

# Найти имя контейнера
docker ps --format '{{.Names}}' | grep sawab-web

# Просмотр логов
docker logs CONTAINER_NAME --tail 100 | grep -i "oauth\|smtp\|mail"
```

### Повторная отправка подтверждения email

```ruby
# В Rails console
kamal console

# Найти неподтвержденных пользователей
User.where(confirmed_at: nil).each do |user|
  user.send_confirmation_instructions
  puts "Sent to #{user.email}"
end
```

---

## Структура файлов

```
.
├── app/
│   ├── controllers/
│   │   └── users/
│   │       └── omniauth_callbacks_controller.rb
│   ├── models/
│   │   └── user.rb                    # from_omniauth метод
│   └── views/
│       └── devise/
│           ├── sessions/
│           │   └── new.html.erb       # Google кнопка
│           └── registrations/
│               └── new.html.erb       # Google кнопка
├── config/
│   ├── environments/
│   │   └── production.rb              # SMTP настройки
│   ├── initializers/
│   │   ├── devise.rb                  # OmniAuth config
│   │   ├── omniauth.rb                # OmniAuth settings
│   │   └── content_security_policy.rb # CSP для Google
│   └── routes.rb                      # OmniAuth routes
├── .kamal/
│   └── secrets                        # SMTP & OAuth secrets
└── docs/
    └── AUTHENTICATION_GUIDE.md        # Это руководство
```

---

## Чек-лист настройки

### Email (Gmail SMTP)

- [ ] 2FA включена в Google аккаунте
- [ ] App Password создан
- [ ] `SMTP_USERNAME` добавлен в GitHub Secrets
- [ ] `SMTP_PASSWORD` добавлен в GitHub Secrets (без пробелов!)
- [ ] Переменные добавлены в `.kamal/secrets`
- [ ] Переменные добавлены в `config/deploy.yml`

### Google OAuth

- [ ] Проект создан в Google Cloud Console
- [ ] OAuth consent screen настроен
- [ ] Scopes добавлены: `email`, `profile`
- [ ] OAuth Client ID создан
- [ ] Redirect URI: `https://your-domain.com/users/auth/google_oauth2/callback`
- [ ] `GOOGLE_CLIENT_ID` добавлен в GitHub Secrets
- [ ] `GOOGLE_CLIENT_SECRET` добавлен в GitHub Secrets
- [ ] Переменные добавлены в `.kamal/secrets`
- [ ] Переменные добавлены в `config/deploy.yml`
- [ ] CSP обновлён: `form_action` включает `accounts.google.com`
- [ ] `config/initializers/omniauth.rb` создан
- [ ] Приложение опубликовано (не в Testing режиме)

---

## Контакты и ресурсы

- [Devise Documentation](https://github.com/heartcombo/devise)
- [OmniAuth Google OAuth2](https://github.com/zquestz/omniauth-google-oauth2)
- [Google Cloud Console](https://console.cloud.google.com)
- [Gmail App Passwords](https://myaccount.google.com/apppasswords)
- [Cloudflare Email Routing](https://developers.cloudflare.com/email-routing/)
