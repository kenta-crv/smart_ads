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

  get 'user/subscription', to: 'user/subscriptions#show', as: :user_subscription
  patch 'user/subscription', to: 'user/subscriptions#update'
  post 'user/subscription/cancel', to: 'user/subscriptions#cancel', as: :cancel_user_subscription

  # Users and nested resources
  resources :users do
    # Campaigns nested under users
    resources :campaigns do
      post :send_campaign, on: :member
      get :confirm_payment, on: :member, as: :confirm_payment
    end

    # Install script (singleton per user)
    resource :install_script, only: [:show] do
      get :test
    end

    # Push subscriptions
    resources :push_subscriptions, only: [:index, :create]
  end

  get 'checkout/confirmation', to: 'checkout#confirmation', as: :checkout_confirmation
  post 'checkout/create', to: 'checkout#create', as: :checkout_create
  get 'checkout/success', to: 'checkout#success', as: :checkout_success
  get 'checkout/cancel', to: 'checkout#cancel', as: :checkout_cancel

  get 'plans', to: 'plans#index', as: :plans
  post 'plans/select', to: 'plans#select', as: :select_plan

  get 'embed.js', to: 'embed#show', as: :embed_script
  match 'embed/register', to: 'embed#register', via: [:post, :options], as: :embed_register

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Default root
  root "home#index"
end
