Rails.application.routes.draw do
  get 'home/index'
  # Devise routes for Users (clients)
  devise_for :users, path: "", controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  # Devise routes for Admins (admins + super admin)
  devise_for :admins, path: "admin", controllers: {
    sessions: "admins/sessions",
    registrations: "admins/registrations",
    passwords: "admins/passwords"
  }

  # Dashboards
  namespace :admin do
    root "dashboard#index"   # /admin
    resources :clients       # managed by admins
    resources :admins, only: [:index, :new, :create, :edit, :update, :destroy] # super_admin only
  end

  namespace :client do
    root "dashboard#index"   # /client
    resources :campaigns
    resources :notifications
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Default root
  root "home#index"
end
