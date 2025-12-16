# frozen_string_literal: true

class AddPerformanceCompositeIndexes < ActiveRecord::Migration[8.0]
  def change
    # Offers: optimize "recent offers on request" queries
    add_index :offers, %i[request_id created_at],
              name: "index_offers_on_request_and_created",
              if_not_exists: true

    # Messages: optimize user message history queries
    add_index :messages, %i[user_id created_at],
              name: "index_messages_on_user_and_created",
              if_not_exists: true

    # Conversations: optimize conversation history queries
    add_index :conversations, %i[asker_id created_at],
              name: "index_conversations_on_asker_and_created",
              if_not_exists: true

    add_index :conversations, %i[helper_id created_at],
              name: "index_conversations_on_helper_and_created",
              if_not_exists: true

    # Reviews: optimize reviewee reviews listing
    add_index :reviews, %i[reviewee_id created_at],
              name: "index_reviews_on_reviewee_and_created",
              if_not_exists: true

    # Notifications: partial index for unread notifications (common query)
    # This is more efficient than scanning all notifications
    add_index :notifications, %i[recipient_id created_at],
              where: "read_at IS NULL",
              name: "index_notifications_unread",
              if_not_exists: true

    # Requests: optimize active requests queries (non-completed/cancelled)
    add_index :requests, %i[user_id status created_at],
              name: "index_requests_on_user_status_created",
              if_not_exists: true
  end
end
