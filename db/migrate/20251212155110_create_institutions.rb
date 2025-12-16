class CreateInstitutions < ActiveRecord::Migration[8.0]
  def change
    create_table :institutions do |t|
      t.string :name, null: false
      t.integer :institution_type, null: false, default: 0
      t.string :address, null: false
      t.string :city, null: false
      t.string :region, null: false
      t.string :phone, null: false
      t.string :email
      t.string :director_name, null: false
      t.text :description
      t.boolean :verified, default: false, null: false
      t.datetime :verified_at
      t.string :website

      t.timestamps
    end

    add_index :institutions, :institution_type
    add_index :institutions, :verified
    add_index :institutions, :region
    add_index :institutions, :city
  end
end
