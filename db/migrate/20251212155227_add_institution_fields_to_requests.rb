class AddInstitutionFieldsToRequests < ActiveRecord::Migration[8.0]
  def change
    add_reference :requests, :institution, null: true, foreign_key: true
    add_column :requests, :help_type, :integer, default: 0
    add_column :requests, :beneficiary_name, :string
    add_column :requests, :beneficiary_age, :integer
    add_column :requests, :author_name, :string

    add_index :requests, :help_type
  end
end
