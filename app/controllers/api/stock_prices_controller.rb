# API：查詢股票即時價格
class Api::StockPricesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :show, :history ]

  def show
    symbol = params[:symbol]
    service = FinmindService.new

    price = service.fetch_latest_price(stock_id: symbol)

    if price
      render_success({
        symbol: symbol,
        price: price,
        updated_at: Time.current
      })
    else
      render_error("無法取得股價", status: :not_found, code: "PRICE_NOT_FOUND")
    end
  end

  def history
    symbol = params[:symbol]

    if params[:days].present?
      days = params[:days].to_i
      daily_prices = DailyPrice.for_symbol(symbol).recent(days)
    elsif params[:from].present?
      from = Date.parse(params[:from])
      to = params[:to].present? ? Date.parse(params[:to]) : Date.today
      daily_prices = DailyPrice.for_symbol(symbol).in_date_range(from, to).order(date: :asc)
    else
      daily_prices = DailyPrice.for_symbol(symbol).recent(30)
    end

    render_success({
      symbol: symbol,
      data: daily_prices.as_json(only: [ :date, :open, :high, :low, :close, :volume ]),
      count: daily_prices.size
    })
  end

  def import
    unless current_user&.admin?
      render_error("需要管理員權限", status: :forbidden, code: "ADMIN_REQUIRED")
      return
    end
    symbol = params[:symbol]
    days = params[:days]&.to_i || 30

    service = StockPriceImportService.new(symbol)
    result = service.import_recent_data(days)

    if result[:success]
      render_success(result)
    else
      render_error(result[:message], status: :unprocessable_entity)
    end
  end

  private
end
