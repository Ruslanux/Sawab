# Provides cached counter functionality for models
# Caches counts with configurable TTL and automatic invalidation
#
# Usage:
#   class User < ApplicationRecord
#     include CachedCounter
#
#     cached_counter :unread_notifications,
#       association: :notifications,
#       scope: :unread,
#       expires_in: 5.minutes
#
#     cached_counter :unread_admin_messages,
#       association: :received_admin_messages,
#       scope: :unread,
#       expires_in: 5.minutes
#   end
#
#   user.unread_notifications_count  # => cached count
#   user.clear_unread_notifications_cache  # => clears cache
#
module CachedCounter
  extend ActiveSupport::Concern

  class_methods do
    def cached_counter(name, association:, scope: nil, expires_in: 5.minutes)
      cache_key_method = "#{name}_cache_key"
      count_method = "#{name}_count"
      clear_method = "clear_#{name}_cache"

      # Define cache key method
      define_method(cache_key_method) do
        "#{self.class.name.underscore}_#{id}_#{name}"
      end

      # Define count method with caching
      define_method(count_method) do
        Rails.cache.fetch(send(cache_key_method), expires_in: expires_in) do
          assoc = send(association)
          scope ? assoc.send(scope).count : assoc.count
        end
      end

      # Define cache clear method
      define_method(clear_method) do
        Rails.cache.delete(send(cache_key_method))
      end
    end
  end
end
