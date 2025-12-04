unless Rails.env.test?
  class Rack::Attack
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # 每個 IP 在 1 分鐘內最多發 60 次請求
    throttle("req/ip", limit: 60, period: 1.minute) do |req|
      req.ip
    end

    # 登入 API 每個 IP 在 5 分鐘內最多嘗試 5 次
    throttle("logins/ip", limit: 5, period: 5.minutes) do |req|
      if req.path == "/api/sessions/sign_in" && req.post?
        req.ip
      end
     end

    # 每個 IP 每小時最多註冊 3 個帳號
    throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
      if req.path == "/api/sessions" && req.post?
        req.ip
      end
    end

    # 下單 API 每個用戶每分鐘最多 10 次
    throttle("orders/user", limit: 10, period: 1.minute) do |req|
      if req.path == "/api/orders" && req.post?
        req.ip if req.env["warden"]&.user
      end
     end

    # 當請求被限制時，回傳什麼內容給用戶
    self.throttled_responder = lambda do |request|
      match_data = request.env["rack.attack.match_data"]
      now = match_data[:epoch_time]
      retry_after = (match_data[:period] - (now % match_data[:period])).to_i

      [
        429,
        {
          "Content-Type" => "application/json",
          "Retry-After" => retry_after.to_s
        },
        [ { error: "請求過於頻繁，請稍後再試" }.to_json ]
      ]
    end
  end
end
