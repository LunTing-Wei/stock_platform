# API：查詢股票即時價格
class Api::StockPricesController < Api::BaseController
  skip_before_action :authenticate_user!

  def show
    symbol = params[:symbol]

    if symbol.blank?
      render_error("股票代碼不能為空", status: :bad_request, code: "INVALID_SYMBOL")
      nil
    end

    price_data = fetch_stock_price_with_cache(symbol)

    if price_data[:price]
      render_success({
        symbol: symbol,
        price: price_data[:price],
        date: price_data[:date],
        updated_at: Time.current
      })
    else
      render_error(
        "無法獲取股價：#{price_data[:error]}",
        status: :service_unavailable,
        code: "PRICE_UNAVAILABLE"
      )
    end
  end

  private

  def fetch_stock_price_with_cache(symbol)
    Rails.cache.fetch("stock_price:#{symbol}", expires_in: 1.minute) do
      fetch_stock_price_from_api(symbol)
    end
  end

  def fetch_stock_price_from_api(symbol)
    service = FinmindService.new

    result = service.fetch_stock_price(
      stock_id: symbol,
      start_date: 7.days.ago.to_date.to_s
    )
    if result[:success] && result[:data].present?
      latest_data = result[:data].last

      {
        price: latest_data["close"].to_f,
        date: latest_data["date"],
        error: nil
      }
    else
      {
        price: nil,
        date: nil,
        error: result[:message] || "API 查詢失敗"
      }
    end
  rescue StandardError => e
    Rails.logger.error "Stock price API error for #{symbol}: #{e.message}"

    {
      price: nil,
      date: nil,
      error: e.message
    }
  end
end
