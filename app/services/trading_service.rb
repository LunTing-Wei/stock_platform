class TradingService
  class InsufficientPositionError < StandardError; end
  class InsufficientFundsError < StandardError; end

  COMMISSION_RATE = 0.001425
  DISCOUNT_RATE = 0.6
  TAX_RATE = 0.003
  MIN_COMMISSION = 1

  def initialize(user)
    @user = user
    @account = user.account

    raise "用戶沒有帳戶" if @account.nil?
  end

  def execute_order(symbol:, side:, quantity:, price:)
    validate_params!(symbol, quantity, price)

    ActiveRecord::Base.transaction do
      @account.lock!

      position = @user.positions.lock.find_by(symbol: symbol)

      case side.to_s
      when "buy"
        execute_buy_order(symbol, quantity, price, position)
      when "sell"
        execute_sell_order(symbol, quantity, price, position)
      else
        raise ArgumentError, "無效的交易方向：#{side}"
      end
    end
  end

  def create_order(symbol:, side:, quantity:, price:)
    validate_params!(symbol, quantity, price)

    @user.orders.create!(
      symbol: symbol,
      side: side.to_sym,
      quantity: quantity,
      price: price,
      status: :pending
    )
  end

  def execute_pending_order(order)
    raise ArgumentError, "訂單不屬於此用戶" unless order.user_id == @user.id
    raise ArgumentError, "只能執行 pending 狀態的訂單" unless order.pending?

    ActiveRecord::Base.transaction do
      @account.lock!
      position = @user.positions.lock.find_by(symbol: order.symbol)

      case order.side
      when "buy"
        execute_buy_transaction(order, position)
      when "sell"
        execute_sell_transaction(order, position)
      end

      order.execute!
    end

    order
  end

  private

  def calculate_commission(amount)
    commission = (amount * COMMISSION_RATE * DISCOUNT_RATE).to_d
    commission = commission.round(0)
    [ commission, MIN_COMMISSION ].max
  end

  def calculate_tax(amount)
    tax = (amount * TAX_RATE).to_d

    tax.round(0)
  end

  def validate_params!(symbol, quantity, price)
    raise ArgumentError, "股票代碼不能為空" if symbol.blank?
    raise ArgumentError, "數量必須大於 0" if quantity <= 0
    raise ArgumentError, "價格必須大於 0" if price <= 0
  end

  def execute_buy_transaction(order, position)
    trade_amount = (order.quantity * order.price).to_d
    commission = calculate_commission(trade_amount)

    total_cost = trade_amount + commission
    if @account.balance < total_cost
      raise InsufficientFundsError, "餘額不足。需要 #{total_cost}(含手續費 #{commission}),可用 #{@account.balance}"
    end

    @account.debit!(
      trade_amount,
      transaction_type: :buy,
      description: "買入 #{order.symbol} #{order.quantity} 股 @ #{order.price}",
      transactionable: order
    )

    @account.debit!(
      commission,
      transaction_type: :fee,
      description: "買入手續費 (#{order.symbol})",
      transactionable: order
    )

    update_position_for_buy(order.symbol, order.quantity, order.price, position)
  end

  def execute_sell_transaction(order, position)
    trade_amount = (order.quantity * order.price).to_d
    commission = calculate_commission(trade_amount)
    tax = calculate_tax(trade_amount)

    if position.nil? || position.quantity < order.quantity
      raise InsufficientPositionError, "持倉不足。需要 #{order.quantity},可用 #{position&.quantity || 0}"
    end

    @account.credit!(
      trade_amount,
      transaction_type: :sell,
      description: "賣出 #{order.symbol} #{order.quantity} 股 @ #{order.price}",
      transactionable: order
    )

    @account.debit!(
      commission,
      transaction_type: :fee,
      description: "賣出手續費 (#{order.symbol})",
      transactionable: order
    )

    @account.debit!(
      tax,
      transaction_type: :fee,
      description: "證券交易稅 (#{order.symbol})",
      transactionable: order
    )

    update_position_for_sell(position, order.quantity)
  end

  def execute_buy_order(symbol, quantity, price, position)
    order = @user.orders.create!(
      symbol: symbol,
      side: :buy,
      quantity: quantity,
      price: price,
      status: :pending
    )
    execute_buy_transaction(order, position)
    order.execute!

    order
  end

  def execute_sell_order(symbol, quantity, price, position)
    order = @user.orders.create!(
      symbol: symbol,
      side: :sell,
      quantity: quantity,
      price: price,
      status: :pending
    )
    execute_sell_transaction(order, position)
    order.execute!

    order
  end

  def update_position_for_buy(symbol, quantity, price, position)
    if position.nil?
      position = @user.positions.build(
        symbol: symbol,
        quantity: quantity,
        average_cost: price,
        current_price: price
      )
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
