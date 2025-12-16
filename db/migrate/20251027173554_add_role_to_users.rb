class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: 'user', null: false
    add_column :users, :banned_at, :datetime
    add_column :users, :banned_reason, :text

    # Добавляем индексы
    add_index :users, :role
    add_index :users, :banned_at

    # Создаем первого админа (замените email на свой)
    reversible do |dir|
      dir.up do
        # Обновляем существующих пользователей без роли
        User.where(role: nil).update_all(role: 'user')

        # Делаем первого пользователя админом (если существует)
        User.find_by(email: 'zhubanov1090@gmail.com')&.update(role: 'admin')
      end
    end
  end
end
