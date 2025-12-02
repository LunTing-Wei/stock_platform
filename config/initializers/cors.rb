Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins case Rails.env
    when "development"
              [ "http://localhost:5173", "http://localhost:3000" ]
    when "production"
              ENV.fetch("FRONTEND_URL") {
                raise "FRONTEND_URL environment variable must be set in production"
              }
    when "test"
              [ "http://localhost:5173", "http://localhost:3000" ]
    else
              "http://localhost:5173"
    end

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
