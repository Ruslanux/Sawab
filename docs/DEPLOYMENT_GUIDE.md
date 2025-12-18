# Руководство по развертыванию Sawab

Это руководство описывает полный процесс развертывания приложения Sawab на продакшн-сервер.

## Содержание

1. [Обзор архитектуры](#обзор-архитектуры)
2. [Предварительные требования](#предварительные-требования)
3. [Настройка Docker Hub](#настройка-docker-hub)
4. [Регистрация домена](#регистрация-домена)
5. [Создание сервера](#создание-сервера)
6. [Настройка PostgreSQL](#настройка-postgresql)
7. [Настройка DNS](#настройка-dns)
8. [Настройка GitHub Secrets](#настройка-github-secrets)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Первый деплой](#первый-деплой)
11. [Мониторинг и отладка](#мониторинг-и-отладка)

---

## Обзор архитектуры

### Используемые технологии

- **Kamal** - инструмент для деплоя Docker-контейнеров
- **Docker Hub** - реестр Docker-образов
- **Hetzner Cloud** - хостинг-провайдер
- **Cloudflare** - DNS и SSL
- **GitHub Actions** - CI/CD

### Структура CI/CD

Мы используем **единый файл** `.github/workflows/ci.yml` для CI и CD вместо раздельных файлов. Это упрощает конфигурацию и гарантирует, что деплой происходит только после успешного прохождения всех тестов.

```
CI/CD Pipeline:
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  scan_ruby  │   │   scan_js   │   │    lint     │   │    test     │   │   deploy    │
│  (Brakeman) │   │ (importmap) │   │  (RuboCop)  │   │  (Minitest) │   │   (Kamal)   │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
       │                 │                 │                 │                 │
       └─────────────────┴─────────────────┴─────────────────┘                 │
                                    │                                          │
                                    ▼                                          │
                         Параллельное выполнение                               │
                                    │                                          │
                                    └──────────────────────────────────────────┘
                                                      │
                                                      ▼
                                          Последовательный деплой
                                          (только после успеха всех)
```

---

## Предварительные требования

### Локальная машина

```bash
# Ruby и Rails
ruby --version  # >= 3.4.4
rails --version # >= 8.0.3

# Docker
docker --version

# GitHub CLI
gh --version

# Kamal
gem install kamal
kamal version
```

### Аккаунты

- [Docker Hub](https://hub.docker.com/) - для хранения Docker-образов
- [Hetzner Cloud](https://www.hetzner.com/cloud) - для сервера (или другой провайдер)
- [Cloudflare](https://www.cloudflare.com/) - для DNS и SSL
- [GitHub](https://github.com/) - для репозитория и CI/CD

---

## Настройка Docker Hub

### 1. Создание аккаунта

1. Зарегистрируйтесь на [hub.docker.com](https://hub.docker.com/)
2. Подтвердите email

### 2. Создание Access Token

1. Перейдите в **Account Settings** → **Security** → **Access Tokens**
2. Нажмите **New Access Token**
3. Настройки:
   - **Description**: `Sawab GitHub Actions`
   - **Access permissions**: `Read & Write`
4. **Сохраните токен** - он показывается только один раз!

### 3. Создание репозитория

1. **Create Repository**
2. Настройки:
   - **Name**: `sawab`
   - **Visibility**: Public или Private

---

## Регистрация домена

### Cloudflare

1. Зарегистрируйте или перенесите домен в Cloudflare
2. Для нашего проекта: `sawabapp.org`

### Настройки SSL/TLS

1. Перейдите в **SSL/TLS** → **Overview**
2. Установите режим: **Full** (не Full Strict!)
   - Это позволяет использовать самоподписанный сертификат Let's Encrypt на сервере

---

## Создание сервера

### Hetzner Cloud

#### 1. Создание проекта

1. Войдите в [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. **New Project** → `Sawab Production`

#### 2. Создание сервера

1. **Add Server**
2. Настройки:
   - **Location**: `Helsinki` (или ближайший к пользователям)
   - **Image**: `Ubuntu 24.04`
   - **Type**: `CX22` (2 vCPU, 4 GB RAM) - минимум для Rails
   - **Networking**: IPv4 включен
   - **SSH Keys**: Добавьте ваш публичный ключ

#### 3. Генерация SSH-ключа (если нет)

```bash
# Генерация нового ключа
ssh-keygen -t ed25519 -C "deploy@sawab" -f ~/.ssh/sawab_deploy

# Копирование публичного ключа
cat ~/.ssh/sawab_deploy.pub
```

#### 4. Начальная настройка сервера

```bash
# Подключение к серверу
ssh root@YOUR_SERVER_IP

# Обновление системы
apt update && apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com | sh

# Проверка Docker
docker --version
docker run hello-world

# Создание Docker network для Kamal
docker network create kamal
```

---

## Настройка PostgreSQL

PostgreSQL разворачивается как Docker-контейнер через Kamal accessories.

### Конфигурация в deploy.yml

```yaml
accessories:
  db:
    image: postgres:16
    host: YOUR_SERVER_IP
    port: "127.0.0.1:5432:5432"  # Только localhost
    env:
      clear:
        POSTGRES_DB: sawab_production
        POSTGRES_USER: sawab
      secret:
        - SAWAB_DATABASE_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
    options:
      network: kamal
```

### Важные моменты

1. **Порт привязан к localhost** - база недоступна извне
2. **Network: kamal** - контейнеры общаются через Docker network
3. **Persistent volume** - данные сохраняются при перезапуске

---

## Настройка DNS

### Cloudflare DNS Records

Добавьте следующие записи:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | @ | YOUR_SERVER_IP | Proxied |
| A | www | YOUR_SERVER_IP | Proxied |

### Проверка DNS

```bash
# Проверка A-записи
dig sawabapp.org +short

# Проверка распространения
nslookup sawabapp.org
```

---

## Настройка GitHub Secrets

### Переход к настройкам

1. GitHub Repository → **Settings** → **Secrets and variables** → **Actions**

### Необходимые секреты

| Secret | Описание | Пример |
|--------|----------|--------|
| `DOCKERHUB_USERNAME` | Имя пользователя Docker Hub | `ruslanux` |
| `DOCKERHUB_TOKEN` | Access Token Docker Hub | `dckr_pat_xxx...` |
| `SSH_PRIVATE_KEY` | Приватный SSH-ключ | Содержимое `~/.ssh/sawab_deploy` |
| `SERVER_IP` | IP-адрес сервера | `65.108.56.69` |
| `RAILS_MASTER_KEY` | Master key Rails | Содержимое `config/master.key` |
| `SAWAB_DATABASE_PASSWORD` | Пароль PostgreSQL | Сгенерированный пароль |

### Генерация пароля базы данных

```bash
# Генерация безопасного пароля
openssl rand -base64 32
```

### Получение SSH-ключа

```bash
# Копирование приватного ключа
cat ~/.ssh/sawab_deploy
```

---

## CI/CD Pipeline

### Структура .github/workflows/ci.yml

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  # ===== ПАРАЛЛЕЛЬНЫЕ ПРОВЕРКИ =====

  scan_ruby:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
      - run: bin/brakeman --no-pager

  scan_js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
      - run: bin/importmap audit

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
      - run: bin/rubocop -f github

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=3
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
      - run: bin/rails db:test:prepare test test:system
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432

  # ===== ДЕПЛОЙ (после всех проверок) =====

  deploy:
    runs-on: ubuntu-latest
    needs: [scan_ruby, scan_js, lint, test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts

      - name: Deploy with Kamal
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.DOCKERHUB_TOKEN }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
          SAWAB_DATABASE_PASSWORD: ${{ secrets.SAWAB_DATABASE_PASSWORD }}
          SERVER_IP: ${{ secrets.SERVER_IP }}
        run: |
          gem install kamal

          # Проверка: первый деплой или обновление
          if ssh root@${SERVER_IP} "docker ps --format '{{.Names}}' | grep -q sawab-web"; then
            echo "=== Обновление существующего деплоя ==="
            kamal deploy
          else
            echo "=== Первый деплой ==="
            kamal build push
            kamal accessory boot db || echo "DB already running"
            ssh root@${SERVER_IP} "docker pull ruslanux/sawab:latest"

            # Миграции базы данных
            ssh root@${SERVER_IP} "docker run --rm --network kamal \
              -e DATABASE_URL='postgres://sawab:${SAWAB_DATABASE_PASSWORD}@sawab-db:5432/sawab_production?sslmode=disable' \
              -e RAILS_MASTER_KEY='${RAILS_MASTER_KEY}' \
              -e RAILS_ENV=production \
              -e SOLID_QUEUE_IN_PUMA=false \
              ruslanux/sawab:latest bin/rails db:prepare"

            kamal deploy --skip-push
          fi
```

### Почему один файл вместо двух?

**Преимущества единого ci.yml:**

1. **Гарантия последовательности** - деплой запускается только после успеха ВСЕХ проверок
2. **Простота конфигурации** - один файл вместо двух
3. **Меньше дублирования** - общие шаги (checkout, setup-ruby) не повторяются
4. **Атомарность** - весь pipeline виден в одном месте
5. **Проще отладка** - все логи в одном run

**Недостатки раздельных ci.yml и cd.yml:**

1. `workflow_run` триггер может быть ненадежным
2. Сложнее передавать артефакты между workflows
3. Больше файлов для поддержки

---

## Первый деплой

### Шаг 1: Локальная проверка

```bash
# Проверка конфигурации Kamal
kamal config

# Проверка подключения к серверу
kamal server bootstrap
```

### Шаг 2: Запуск деплоя

```bash
# Коммит и пуш в main
git add .
git commit -m "Initial deployment setup"
git push origin main
```

### Шаг 3: Мониторинг CI/CD

```bash
# Просмотр запущенных workflows
gh run list --repo YOUR_USERNAME/Sawab

# Просмотр логов конкретного run
gh run view RUN_ID --log

# Просмотр только ошибок
gh run view RUN_ID --log-failed
```

### Шаг 4: Проверка деплоя

```bash
# Health check
curl -I https://sawabapp.org/up

# Проверка контейнеров на сервере
ssh root@YOUR_SERVER_IP "docker ps"

# Логи приложения
ssh root@YOUR_SERVER_IP "docker logs sawab-web"
```

---

## Мониторинг и отладка

### Полезные команды Kamal

```bash
# Просмотр логов в реальном времени
kamal logs -f

# Подключение к Rails console
kamal console

# Подключение к bash в контейнере
kamal shell

# Подключение к базе данных
kamal dbc

# Запуск миграций
kamal migrate

# Перезапуск приложения
kamal app restart

# Откат к предыдущей версии
kamal rollback
```

### SSH-команды для сервера

```bash
# Статус контейнеров
docker ps -a

# Логи конкретного контейнера
docker logs sawab-web --tail 100 -f

# Использование ресурсов
docker stats

# Состояние базы данных
docker exec sawab-db psql -U sawab -d sawab_production -c "\dt"

# Очистка неиспользуемых образов
docker system prune -a
```

### Решение типичных проблем

#### Ошибка "solid_cache_entries does not exist"

Таблицы Solid Cache/Queue/Cable не созданы. Решение:

```bash
# На сервере
docker exec -it sawab-web bin/rails db:migrate
```

#### Ошибка подключения к базе данных

1. Проверьте, что контейнер базы запущен:
   ```bash
   docker ps | grep sawab-db
   ```

2. Проверьте сеть:
   ```bash
   docker network inspect kamal
   ```

3. Проверьте переменные окружения:
   ```bash
   docker exec sawab-web env | grep DATABASE
   ```

#### Health check не проходит

1. Проверьте логи:
   ```bash
   docker logs sawab-web --tail 50
   ```

2. Проверьте /up endpoint внутри контейнера:
   ```bash
   docker exec sawab-web curl -v http://localhost:3000/up
   ```

---

## Структура файлов деплоя

```
.
├── .github/
│   └── workflows/
│       └── ci.yml              # CI/CD pipeline (единый файл)
├── .kamal/
│   └── secrets                 # Локальные секреты (не в git)
├── config/
│   ├── deploy.yml              # Конфигурация Kamal
│   └── database.yml            # Настройки базы данных
├── Dockerfile                   # Сборка образа
└── docs/
    └── DEPLOYMENT_GUIDE.md     # Это руководство
```

---

## Чек-лист перед деплоем

- [ ] Docker Hub аккаунт создан
- [ ] Docker Hub access token сгенерирован
- [ ] Домен зарегистрирован и настроен в Cloudflare
- [ ] SSL/TLS режим установлен в "Full"
- [ ] Сервер создан и настроен
- [ ] SSH-ключ добавлен на сервер
- [ ] Docker установлен на сервере
- [ ] Docker network 'kamal' создана
- [ ] DNS A-записи созданы
- [ ] GitHub Secrets настроены:
  - [ ] DOCKERHUB_USERNAME
  - [ ] DOCKERHUB_TOKEN
  - [ ] SSH_PRIVATE_KEY
  - [ ] SERVER_IP
  - [ ] RAILS_MASTER_KEY
  - [ ] SAWAB_DATABASE_PASSWORD
- [ ] Тесты проходят локально
- [ ] config/deploy.yml настроен

---

## Контакты и ресурсы

- [Kamal Documentation](https://kamal-deploy.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Hetzner Cloud Documentation](https://docs.hetzner.com/cloud/)
- [Cloudflare Documentation](https://developers.cloudflare.com/)
