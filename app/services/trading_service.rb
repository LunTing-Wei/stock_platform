class TradingService
  class InsufficientPositionError < StandardError; end
  class InsufficientFundsError < StandardError; end

  def initialize(user)
    @user = user
    @account = user.account

    raise "用戶沒有帳戶" if @account.nil?
  end

  def execute_order(symbol:, side:, quantity:, price:)
    validate_params!(symbol, quantity, price)

    ActiveRecord::Base.transaction do
      @account.lock!

      case side.to_s
      when "buy"
        execute_buy_order(symbol, quantity, price)
      when "sell"
        execute_sell_order(symbol, quantity, price)
      else
        raise ArgumentError, "無效的交易方向：#{side}"
      end
    end
  end

  private

  def validate_params!(symbol, quantity, price)
    raise ArgumentError, "股票代碼不能為空" if symbol.blank?
    raise ArgumentError, "數量必須大於 0" if quantity <= 0
    raise ArgumentError, "價格必須大於 0" if price <= 0
  end

  def execute_buy_order(symbol, quantity, price)
    total_cost = (quantity * price).to_d

    if @account.balance < total_cost
      raise InsufficientFundsError, "餘額不足。需要 #{total_cost}，可用 #{@account.balance}"
    end

    order = @user.orders.create!(
      symbol: symbol,
      side: :buy,
      quantity: quantity,
      price: price,
      status: :completed,
      executed_at: Time.current
    )

    # 扣除帳戶餘額
    @account.debit!(
      total_cost,
      transaction_type: :buy,
      description: "買入 #{symbol} #{quantity} 股 @ #{price}",
      transactionable: order
    )

    update_position_for_buy(symbol, quantity, price)

    order
  end

  def execute_sell_order(symbol, quantity, price)
    total_proceeds = (quantity * price).to_d

    # 檢查持倉（使用悲觀鎖）
    position = @user.positions.lock.find_by(symbol: symbol)

    if position.nil? || position.quantity < quantity
      raise InsufficientPositionError, "持倉不足。需要 #{quantity}，可用 #{position&.quantity || 0}"
    end

    order = @user.orders.create!(
      symbol: symbol,
      side: :sell,
      quantity: quantity,
      price: price,
      status: :completed,
      executed_at: Time.current
    )

    # 增加帳戶餘額
    @account.credit!(
      total_proceeds,
      transaction_type: :sell,
      description: "賣出 #{symbol} #{quantity} 股 @ #{price}",
      transactionable: order
    )

    # 更新持倉
    update_position_for_sell(position, quantity)

    order
  end

  def update_position_for_buy(symbol, quantity, price)
    position = @user.positions.find_or_initialize_by(symbol: symbol)

    if position.new_record?
      position.quantity = quantity
      position.average_cost = price
      position.current_price = price
    else
      total_cost = position.quantity * position.average_cost + quantity * price
      position.quantity += quantity
      position.average_cost = total_cost / position.quantity
    end

    position.save!
  end

  def update_position_for_sell(position, quantity)
    position.quantity -= quantity

    if position.quantity.zero?
      position.destroy!
    else
      position.save!
    end
  end
end
