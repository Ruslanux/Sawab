Rails.application.routes.draw do
  scope "(:locale)", locale: /en|kk|ru/ do
    devise_for :users

    root "requests#index"

    # Static pages
    get "about", to: "static_pages#about", as: :about
    get "guidelines", to: "static_pages#guidelines", as: :guidelines

    resources :reports, only: [ :new, :create ]

    # МАРШРУТЫ ДЛЯ УВЕДОМЛЕНИЙ
    resources :notifications, only: [ :index, :destroy ] do
      member do
        patch :mark_as_read
      end

      collection do
        patch :mark_all_as_read
      end
    end

    # МАРШРУТ: Инбокс для пользователя
    resources :admin_messages, only: [ :index, :show, :create ]

    resources :leaderboards, only: [ :index ], path: "leaderboard"

    # Учреждения (ЦПДСиС, дома-интернаты, пансионаты)
    resources :institutions do
      resources :institution_members, only: [ :index, :create, :update, :destroy ]
      member do
        get :requests
      end
      collection do
        get :my_institutions
      end
    end

    # Requests и Offers
    resources :requests do
      resources :offers, only: [ :create, :update ], shallow: true
      resource :conversation, only: [ :show ]
      resources :reviews, only: [ :new, :create ], shallow: true

      member do
        patch :complete
        patch :cancel
        patch :mark_pending_completion
      end

      collection do
        get :stats
      end
    end

    # МАРШРУТ ДЛЯ СООБЩЕНИЙ
    resources :conversations, only: [] do
      resources :messages, only: [ :create ]
    end

    # User profile routes
    get "profile/edit", to: "users#edit", as: :edit_profile
    patch "profile", to: "users#update", as: :profile
    delete "profile/avatar", to: "users#remove_avatar", as: :remove_avatar_profile
    delete "profile", to: "users#destroy", as: :destroy_profile

    # Профили пользователей - /users/:username
    resources :users, only: [ :show ], param: :username

    # Админ панель
    namespace :admin do
      root to: "dashboard#index"

      resources :users do
        member do
          post :ban
          post :unban
          post :adjust_sawab
          delete :remove_avatar
        end
      end

      # /admin/admin_messages (Инбокс админа)
      # /admin/admin_messages/:id (Чат админа с юзером :id)
      resources :admin_messages, only: [ :index, :show, :create ]

      resources :requests, only: [ :index, :show, :destroy ] do
        member do
          patch :complete
          patch :cancel
        end
      end

      resources :offers, only: [ :index, :show, :destroy ]

      resources :reports, only: [ :index, :show ] do
        member do
          patch :investigate
          patch :resolve
          patch :dismiss
        end
      end

      resources :categories
      resources :badges
      resources :user_badges, only: [ :create, :destroy ]

      resources :institutions, only: [ :index, :show, :destroy ] do
        member do
          patch :verify
          patch :unverify
        end
      end
    end
  end

  mount ActionCable.server => "/cable"

  # Health check (вне scope для мониторинга)
  get "up" => "rails/health#show", as: :rails_health_check
end
