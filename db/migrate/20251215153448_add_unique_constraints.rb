# frozen_string_literal: true

class AddUniqueConstraints < ActiveRecord::Migration[8.0]
  def up
    # Reviews: unique constraint to prevent duplicate reviews
    # (same reviewer cannot review same reviewee for same request twice)
    add_index :reviews, %i[request_id reviewer_id reviewee_id],
              unique: true,
              name: "index_reviews_uniqueness"

    # Offers: partial unique constraint to prevent duplicate pending offers
    # (same user cannot have multiple pending offers for same request)
    execute <<-SQL
      CREATE UNIQUE INDEX index_offers_unique_pending_per_user_request
      ON offers (user_id, request_id)
      WHERE status = 'pending';
    SQL

    # Users: case-insensitive username uniqueness
    # First, check for and resolve any duplicate usernames (case-insensitive)
    execute <<-SQL
      WITH duplicates AS (
        SELECT id, username, LOWER(username) as lower_username,
               ROW_NUMBER() OVER (PARTITION BY LOWER(username) ORDER BY id) as rn
        FROM users
      )
      UPDATE users
      SET username = users.username || '_' || users.id
      FROM duplicates
      WHERE users.id = duplicates.id AND duplicates.rn > 1;
    SQL

    # Add unique index on lowercased username
    execute <<-SQL
      CREATE UNIQUE INDEX index_users_on_lowercase_username
      ON users (LOWER(username));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_users_on_lowercase_username"
    execute "DROP INDEX IF EXISTS index_offers_unique_pending_per_user_request"
    remove_index :reviews, name: "index_reviews_uniqueness", if_exists: true
  end
end
