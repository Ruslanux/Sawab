# =============================================================================
# Sawab - Seed Data
# =============================================================================
# Этот файл содержит начальные данные для приложения.
# Запуск: bin/rails db:seed
#
# ВАЖНО: Seed использует find_or_create_by!, поэтому безопасен для повторного
# запуска — существующие записи не будут дублироваться.
# =============================================================================

puts "=" * 60
puts "Seeding Sawab database..."
puts "=" * 60

# -----------------------------------------------------------------------------
# КАТЕГОРИИ
# -----------------------------------------------------------------------------
# Основные категории помощи на платформе.
# Для каждой категории автоматически должен существовать бейдж "Эксперт: {Категория}"
# -----------------------------------------------------------------------------

puts "\n[1/3] Seeding Categories..."

categories = [
  "Физическая помощь",    # Переезд, погрузка, тяжелая работа
  "Транспорт",            # Отвезти в больницу, аэропорт, доставка
  "Обучение",             # Репетиторство, помощь с учебой
  "Материальная помощь",  # Вещи, одежда, бытовая техника
  "Медицинская помощь",   # Сопровождение в больницу, покупка лекарств
  "Юридическая помощь",   # Документы, консультации по правам
  "Бытовые услуги",       # Мелкий ремонт, уборка для пожилых
  "Другое"                # Всё остальное
]

categories.each do |name|
  Category.find_or_create_by!(name: name)
  print "."
end

puts "\n   Created #{categories.size} categories"

# -----------------------------------------------------------------------------
# БЕЙДЖИ
# -----------------------------------------------------------------------------
# Система наград за активность на платформе.
#
# Типы бейджей:
# 1. За количество Sawab (1, 5, 25)
# 2. За время на платформе (1 год)
# 3. За экспертизу в категории (5 помощей в одной категории)
# -----------------------------------------------------------------------------

puts "\n[2/3] Seeding Badges..."

# Бейджи за количество Sawab
sawab_badges = [
  {
    name: "Первый Sawab",
    description: "Вы заработали свой первый Sawab, завершив запрос!",
    icon_name: "first_sawab"
  },
  {
    name: "Помощник",
    description: "Вы успешно помогли 5 раз.",
    icon_name: "helper"
  },
  {
    name: "Ветеран",
    description: "Вы успешно помогли 25 раз.",
    icon_name: "veteran"
  }
]

# Бейдж за время на платформе
time_badges = [
  {
    name: "Год на Sawab",
    description: "Спасибо, что остаетесь с нами больше года!",
    icon_name: "year_one"
  }
]

# Бейджи за экспертизу в категориях
# icon_name формируется из транслитерации категории
category_expert_badges = [
  { name: "Эксперт: Физическая помощь", icon_name: "physical_expert" },
  { name: "Эксперт: Транспорт", icon_name: "transport_expert" },
  { name: "Эксперт: Обучение", icon_name: "education_expert" },
  { name: "Эксперт: Материальная помощь", icon_name: "material_expert" },
  { name: "Эксперт: Медицинская помощь", icon_name: "medical_expert" },
  { name: "Эксперт: Юридическая помощь", icon_name: "legal_expert" },
  { name: "Эксперт: Бытовые услуги", icon_name: "household_expert" },
  { name: "Эксперт: Другое", icon_name: "other_expert" }
].map do |badge|
  category_name = badge[:name].sub("Эксперт: ", "")
  badge.merge(description: "Вы помогли 5 раз в категории \"#{category_name}\".")
end

all_badges = sawab_badges + time_badges + category_expert_badges

all_badges.each do |attrs|
  Badge.find_or_create_by!(name: attrs[:name]) do |b|
    b.description = attrs[:description]
    b.icon_name = attrs[:icon_name]
  end
  print "."
end

puts "\n   Created #{all_badges.size} badges"

# -----------------------------------------------------------------------------
# АДМИНИСТРАТОР (опционально)
# -----------------------------------------------------------------------------
# Раскомментируйте для создания администратора при первом запуске.
# В продакшене лучше создавать админа вручную или через переменные окружения.
# -----------------------------------------------------------------------------

puts "\n[3/3] Checking for admin user..."

=begin
if User.where(role: "admin").none?
  admin = User.create!(
    username: "admin",
    email: ENV.fetch("ADMIN_EMAIL", "admin@sawab.kz"),
    password: ENV.fetch("ADMIN_PASSWORD", "changeme123"),
    role: "admin",
    confirmed_at: Time.current
  )
  puts "   Created admin user: #{admin.email}"
else
  puts "   Admin user already exists, skipping..."
end
=end

puts "   Skipped (create admin manually for security)"

# -----------------------------------------------------------------------------
# ИТОГ
# -----------------------------------------------------------------------------

puts "\n" + "=" * 60
puts "Seeding completed!"
puts "=" * 60
puts "\nSummary:"
puts "  - Categories: #{Category.count}"
puts "  - Badges: #{Badge.count}"
puts "  - Users: #{User.count}"
puts "\n"
