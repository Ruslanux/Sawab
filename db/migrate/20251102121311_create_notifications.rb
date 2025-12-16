class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }, index: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :action, null: false
      t.datetime :read_at

      t.timestamps
    end

    # Добавляем составные индексы для оптимизации запросов
    add_index :notifications, [ :recipient_id, :read_at ], name: 'index_notifications_on_recipient_and_read'
    add_index :notifications, [ :recipient_id, :created_at ], name: 'index_notifications_on_recipient_and_created'
    add_index :notifications, :action
  end
end
