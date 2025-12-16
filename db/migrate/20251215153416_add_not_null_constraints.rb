# frozen_string_literal: true

class AddNotNullConstraints < ActiveRecord::Migration[8.0]
  def up
    # Badges: name and icon_name are required
    Badge.where(name: nil).update_all(name: "Unknown Badge")
    Badge.where(icon_name: nil).update_all(icon_name: "star")
    change_column_null :badges, :name, false
    change_column_null :badges, :icon_name, false

    # Categories: name is required
    Category.where(name: nil).update_all(name: "Uncategorized")
    change_column_null :categories, :name, false

    # Admin messages: body is required
    AdminMessage.where(body: nil).update_all(body: "")
    change_column_null :admin_messages, :body, false

    # Reviews: rating is required
    Review.where(rating: nil).update_all(rating: 3)
    change_column_null :reviews, :rating, false

    # Offers: message and status are required
    Offer.where(message: nil).update_all(message: "")
    change_column_null :offers, :message, false
    change_column_null :offers, :status, false, "pending"

    # Requests: title, description, status, region, city are required
    Request.where(title: nil).update_all(title: "Untitled")
    Request.where(description: nil).update_all(description: "No description")
    Request.where(region: nil).update_all(region: "almaty")
    Request.where(city: nil).update_all(city: "Almaty")
    change_column_null :requests, :title, false
    change_column_null :requests, :description, false
    change_column_null :requests, :status, false, "open"
    change_column_null :requests, :region, false
    change_column_null :requests, :city, false

    # Users: username and sawab_balance are required
    User.where(username: nil).find_each do |user|
      user.update_column(:username, "user_#{user.id}")
    end
    change_column_null :users, :username, false
    change_column_null :users, :sawab_balance, false, 0
  end

  def down
    change_column_null :badges, :name, true
    change_column_null :badges, :icon_name, true
    change_column_null :categories, :name, true
    change_column_null :admin_messages, :body, true
    change_column_null :reviews, :rating, true
    change_column_null :offers, :message, true
    change_column_null :offers, :status, true
    change_column_null :requests, :title, true
    change_column_null :requests, :description, true
    change_column_null :requests, :status, true
    change_column_null :requests, :region, true
    change_column_null :requests, :city, true
    change_column_null :users, :username, true
    change_column_null :users, :sawab_balance, true
  end
end
