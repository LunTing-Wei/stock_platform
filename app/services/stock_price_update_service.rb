class StockPriceUpdateService
  def initialize(positions = Position.all)
    @positions = positions
    @finmind_service = FinmindService.new
  end

  def call
    results = {
      total: 0,
      success: 0,
      failed: 0,
      errors: []
    }
    @positions.find_each do |position|
      results[:total] += 1

      if update_position_price(position)
        results[:success] += 1
      else
        results[:failed] += 1
        results[:errors] << { symbol: position.symbol, error: "Failed to fetch price" }
      end
    end

    log_results(results)

    results
  end

  private

  def update_position_price(position)
    latest_price = fetch_price(position.symbol)

    return false unless latest_price

    position.update_columns(
      current_price: latest_price,
      price_updated_at: Time.current
    )

    true
  rescue StandardError => e
    Rails.logger.error "Failed to update price for #{position.symbol}: #{e.message}"
    false
  end

  def fetch_price(symbol)
    @finmind_service.fetch_latest_price(stock_id: symbol)
  rescue StandardError => e
    Rails.logger.error "API error for #{symbol}: #{e.message}"
    nil
  end

  def log_results(results)
    Rails.logger.info "Stock price update completed: #{results[:success]}/#{results[:total]} succeeded"

    if results[:failed] > 0
      Rails.logger.warn "Failed to update #{results[:failed]} positions"
    end
  end
end
