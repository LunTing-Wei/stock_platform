class FinmindService
  include HTTParty

  base_uri Rails.application.credentials.finmind[:api_url]

  def initialize
    @token = Rails.application.credentials.finmind[:api_token]
  end

  def fetch_stock_price(stock_id:, start_date: 1.day.ago.to_date.to_s, end_date: Date.today.to_s)
    response = self.class.get("/data", query: build_query(stock_id, start_date, end_date))

    handle_response(response)
  end

  def fetch_latest_price(stock_id:)
    result =fetch_stock_price(stock_id: stock_id, start_date: 7.days.ago.to_date.to_s)

    return nil unless result[:success]

    latest_data = result[:data].last
    latest_data&.dig("close")&.to_f
  end

  private

  def build_query(stock_id, start_date, end_date)
    {
      dataset: "TaiwanStockPrice",
      data_id: stock_id,
      start_date: start_date,
      end_date: end_date,
      token: @token
    }
  end

  def handle_response(response)
    if response.success?
      {
        success: true,
        data: response.parsed_response["data"],
        message: response.parsed_response["msg"]
      }
    else
      {
        success: false,
        data: nil,
        message: "API request failed: #{response.code}"
      }
    end
  rescue StandardError => e
    {
      success: false,
      data: nil,
      message: "Error: #{e.message}"
    }
  end
end
