class StockPriceImportService
  def initialize(symbol)
    @symbol = symbol
    @finmind = FinmindService.new
  end

  def import_historical_data(start_date:, end_date: Date.today)
    result = @finmind.fetch_stock_price(
      stock_id: @symbol,
      start_date: start_date.to_s,
      end_date: end_date.to_s
    )

    unless result[:success]
      return { success: false, message: result[:message], imported: 0 }
    end

    imported_count = 0
    skipped_count = 0
    errors = []

    result[:data].each do |day_data|
      daily_price = DailyPrice.find_or_initialize_by(
        symbol: @symbol,
        date: Date.parse(day_data["date"])
      )

      if daily_price.persisted? && !data_changed?(daily_price, day_data)
        skipped_count += 1
        next
      end

      daily_price.assign_attributes(
        open: day_data["open"].to_f,
        high: day_data["max"].to_f,
        low: day_data["min"].to_f,
        close: day_data["close"].to_f,
        volume: day_data["Trading_Volume"].to_i
      )

      if daily_price.save
        imported_count += 1
      else
        errors << {
          date: day_data["date"],
          errors: daily_price.errors.full_messages
        }
      end
    end

    {
      success: true,
      imported: imported_count,
      skipped: skipped_count,
      errors: errors,
      message: "成功匯入 #{imported_count} 筆，跳過 #{skipped_count} 筆"
    }
  end

  def import_recent_data(days = 30)
    start_date = days.days.ago.to_date
    import_historical_data(start_date: start_date)
  end

  private
  def data_changed?(daily_price, new_data)
    daily_price.open != new_data["open"].to_f ||
    daily_price.high != new_data["max"].to_f ||
    daily_price.low != new_data["min"].to_f ||
    daily_price.close != new_data["close"].to_f ||
    daily_price.volume != new_data["Trading_Volume"].to_i
  end
end
