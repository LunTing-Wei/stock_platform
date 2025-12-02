Sentry.init do |config|
    # Sentry DSN（資料來源名稱）
    # 開發環境可以留空，Sentry 會記錄到 Rails log
    # 生產環境需要從 Sentry 網站取得 DSN
    config.dsn = ENV["SENTRY_DSN"]

    # 設定環境
    config.environment = Rails.env

    # 只在 production 和 staging 環境啟用
    config.enabled_environments = %w[production staging]

    # 取樣率：100% = 記錄所有錯誤
    config.traces_sample_rate = 1.0

    # 要追蹤的 exception 類型
    # 預設會捕獲所有 exceptions，這裡可以排除某些不重要的
    config.excluded_exceptions += [
      "ActionController::RoutingError",
      "ActiveRecord::RecordNotFound"
    ]

    # Sidekiq 整合
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # 過濾敏感資料（不要傳送密碼等敏感資訊）
    config.send_default_pii = false
end
