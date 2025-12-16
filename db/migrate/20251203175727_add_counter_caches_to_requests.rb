class AddCounterCachesToRequests < ActiveRecord::Migration[8.0]
  def change
    # Add counter cache for total offers on a request
    add_column :requests, :offers_count, :integer, default: 0, null: false

    # Backfill existing counts
    reversible do |dir|
      dir.up do
        Request.find_each do |request|
          Request.reset_counters(request.id, :offers)
        end
      end
    end
  end
end
