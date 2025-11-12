Rails.application.routes.draw do
  devise_for :users

  # Api routes
  namespace :api do
    resources :orders, only: [ :index, :show, :create ]

    resource :account, only: [ :show ]
    resources :transactions, only: [ :index ]
    resources :positions, only: [ :index, :show ]
  end

  root "pages#home"
end
