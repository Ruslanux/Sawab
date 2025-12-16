class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :request, null: false, foreign_key: true, index: { unique: true }
      t.references :asker, null: false, foreign_key: { to_table: :users }
      t.references :helper, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Добавляем индексы для оптимизации поиска
    add_index :conversations, [ :asker_id, :helper_id ], name: 'index_conversations_on_participants'
  end
end
