class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reported_user, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.references :resolver, foreign_key: { to_table: :users }

      t.string :report_type, null: false
      t.text :reason, null: false
      t.string :status, default: 'pending', null: false
      t.text :resolution_note
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :reports, :status
    add_index :reports, :report_type
    add_index :reports, [ :reportable_type, :reportable_id ]
  end
end
