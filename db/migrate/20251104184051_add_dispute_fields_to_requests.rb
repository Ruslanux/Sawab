class AddDisputeFieldsToRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :requests, :pending_completion_at, :datetime
  end
end
