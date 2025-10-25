Rails.application.routes.draw do
  get 'home/index'

  # Devise routes for Users
  devise_for :users, path: "", controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  # Devise routes for Admins
  devise_for :admins, path: "admin", controllers: {
    sessions: "admins/sessions",
    registrations: "admins/registrations",
    passwords: "admins/passwords"
  }

  # Dashboards
  namespace :admin do
    get 'dashboard/index'
    root "dashboard#index"
    resources :users
    resources :admins, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  namespace :user do
    get 'dashboard/index'
    root "dashboard#index"
    resources :notifications
  end

  # Users and nested resources
  resources :users do
    # Campaigns nested under users
    resources :campaigns do
      post :send_campaign, on: :member
    end

    # Install script (singleton per user)
    resource :install_script, only: [:show] do
      get :test
    end

    # Push subscriptions
    resources :push_subscriptions, only: [:index, :create]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Default root
  root "home#index"
end
