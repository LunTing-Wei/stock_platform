class TradingService
  class InsufficientPositionError < StandardError; end

  def initialize(user)
    @user = user
  end

  def execute_order(symbol:, side:, quantity:, price:)
    ActiveRecord::Base.transaction do
      order = @user.orders.create!(
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: price,
        status: :completed,
        executed_at: Time.current
      )

      if side.to_s == "buy"
        update_position_for_buy(symbol, quantity, price)
      else
        update_position_for_sell(symbol, quantity)
      end

      order
    end
  end

  private

  def update_position_for_buy(symbol, quantity, price)
    position = @user.positions.find_or_initialize_by(symbol: symbol)

    if position.new_record?
      position.quantity = quantity
      position.average_cost = price
    else
      total_cost = position.quantity * position.average_cost + quantity * price
      position.quantity += quantity
      position.average_cost = total_cost / position.quantity
    end

    position.save!
  end

  def update_position_for_sell(symbol, quantity)
    position = @user.positions.find_by(symbol: symbol)

    if position.nil? || position.quantity < quantity
      raise InsufficientPositionError, "持倉不足，無法賣出"
    end

    position.quantity -= quantity
    if position.quantity.zero?
      position.destroy!
    else
      position.save!
    end
  end
end
