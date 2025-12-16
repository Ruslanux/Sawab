class AddPerformanceIndexesToOffers < ActiveRecord::Migration[8.0]
  def change
    # Add index on status column for filtering
    add_index :offers, :status, if_not_exists: true

    # Add index on created_at for time-based queries
    add_index :offers, :created_at, if_not_exists: true

    # Composite index for common query pattern: filtering offers by request and status
    add_index :offers, [ :request_id, :status ], if_not_exists: true

    # Composite index for filtering user's offers by status
    add_index :offers, [ :user_id, :status ], if_not_exists: true

    # Composite index for admin messages - finding unread messages
    add_index :admin_messages, [ :recipient_id, :read_at ], if_not_exists: true
  end
end
