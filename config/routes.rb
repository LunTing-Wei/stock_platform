Rails.application.routes.draw do
  root to: proc { [ 200, {}, [ '{"status":"ok"}' ] ] }
  namespace :api do
    scope :sessions do
      devise_scope :user do
        post "sign_in", to: "sessions/sessions#create"
        delete "sign_out", to: "sessions/sessions#destroy"
        post "sign_up", to: "sessions/registrations#create"
      end
    end

    # Api routes
    resources :orders, only: [ :index, :show, :create ]

    resource :account, only: [ :show ]
    resources :transactions, only: [ :index ]
    resources :positions, only: [ :index, :show ]
  end
end
