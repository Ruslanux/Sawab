class AddLocationFieldsToRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :requests, :region, :string
    add_column :requests, :city, :string

    add_index :requests, :region
    add_index :requests, :city
    add_index :requests, :status
    add_index :requests, :created_at
    add_index :requests, [ :status, :created_at ]
    add_index :requests, [ :region, :status ]
  end
end
