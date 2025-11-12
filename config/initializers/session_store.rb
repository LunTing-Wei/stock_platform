Rails.application.config.session_store :cookie_store,
  key: "_stock_platform_session",
  domain: :all,
  same_site: :lax
