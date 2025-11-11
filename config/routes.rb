Rails.application.routes.draw do
  devise_for :users

  # Api routes
  namespace :api do
    resources :orders, only: [ :index, :show, :create ]
  end

  root "pages#home"
end
