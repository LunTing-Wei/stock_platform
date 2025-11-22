class UpdateStockPricesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting stock price update job"

    stale_positions = Position.where(
      "price_updated_at IS NULL OR price_updated_at < ?",
      Position::PRICE_REFRESH_INTERVAL.ago
    )

    service  = StockPriceUpdateService.new(stale_positions)
    results = service.call

    Rails.logger.info "Stock price update job completed: #{results}"
  end
end
