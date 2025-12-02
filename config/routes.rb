Rails.application.routes.draw do
  # 載入 Sidekiq 的 Web UI 套件
  require "sidekiq/web"
  require "sidekiq/cron/web"

  # 生產環境的 Sidekiq UI 需要加上認證保護
  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  end

  root to: proc { [ 200, {}, [ '{"status":"ok"}' ] ] }

  # Devise 路由（必須在 namespace 外面，用 scope 包裝）
  scope :api do
    devise_for :users,
      path: "sessions",
      controllers: {
        sessions: "api/sessions/sessions",
        registrations: "api/sessions/registrations"
      },
      defaults: { format: :json }
  end

  namespace :api do
    # Api routes
    resources :orders, only: [ :index, :show, :create ]

    resource :account, only: [ :show ] do
      post :deposit
      post :withdraw
    end
    resources :transactions, only: [ :index ]
    resources :positions, only: [ :index, :show ]

    # 股價查詢 API
    resources :stock_prices, only: [ :show ], param: :symbol do
      member do
        get :history
        post :import
      end
    end
  end
end
