# 設定 Sidekiq worker（執行工作的進程）如何連接 Redis
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  schedule_file = "config/schedule.yml"

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

# 設定 Rails app（產生工作的進程）如何連接 Redis
Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
