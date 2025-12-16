class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    # Индекс для сортировки сообщений по времени
    add_index :messages, [ :conversation_id, :created_at ], name: 'index_messages_on_conversation_and_created'
  end
end
