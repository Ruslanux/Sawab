class CreateInstitutionMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :institution_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :institution, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.string :position

      t.timestamps
    end

    add_index :institution_members, [ :user_id, :institution_id ], unique: true
  end
end
