class Api::OrdersController < Api::BaseController
  def index
    orders = current_user.orders
    authorize Order

    orders = orders.where(symbol: params[:symbol]) if params[:symbol].present?
    orders = orders.where(side: params[:side]) if params[:side].present?
    orders = orders.where(status: params[:status]) if params[:status].present?

    orders = orders.order(created_at: :desc)

    total_count = orders.count

    page = params[:page]&.to_i || 1
    page = [ page, 1 ].max
    per_page  =params[:per_page]&.to_i || 20
    per_page = [ [ per_page, 100 ].min, 1 ].max

    orders = orders.limit(per_page).offset((page - 1) * per_page)

    render_success({
      orders: orders.as_json(only: [ :id, :symbol, :side, :quantity, :price, :status, :executed_at, :created_at ]),
      pagination: {
        current_page: page,
        per_page: per_page,
        total: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    })
  end

  def show
    order = current_user.orders.find(params[:id])
    authorize order

    render_success({
      order: order.as_json(
        only: [ :id, :symbol, :side, :quantity, :price, :status, :executed_at, :created_at, :updated_at ],
        include: {}
      )
    })
  end

  def create
    unless order_params[:symbol].present? &&
           order_params[:side].present? &&
           order_params[:quantity].present? &&
           order_params[:price].present?
      raise ArgumentError, "缺少必要參數"
    end

    # 驗證 symbol 格式
    unless order_params[:symbol].match?(/\A[A-Z]{1,10}\z/)
      raise ArgumentError, "股票代碼格式錯誤(應為1-10個大寫字母)"
    end

    # 驗證 side
    unless %w[buy sell].include?(order_params[:side])
      raise ArgumentError, "交易方向必須是 buy 或 sell"
    end

    # 驗證 quantity
    quantity = order_params[:quantity].to_i
    if quantity <= 0
      raise ArgumentError, "數量必須大於 0"
    end

    # 驗證 price
    begin
      price = BigDecimal(order_params[:price])
    rescue ArgumentError, TypeError
      raise ArgumentError, "價格格式錯誤"
    end

    if price <= 0
      raise ArgumentError, "價格必須大於 0"
    end

    service = TradingService.new(current_user)
    authorize Order

    order = service.execute_order(
      symbol: order_params[:symbol],
      side: order_params[:side].to_sym,
      quantity: quantity,
      price: price
    )

    AuditLog.log(
      user: current_user,
      action: "create_order",
      auditable: order,
      metadata: {
        symbol: order.symbol,
        side: order.side,
        quantity: order.quantity,
        price: order.price.to_f,
        status: order.status
      },
      ip_address: request.remote_ip
    )

    render_success({
      order: order.as_json(only: [ :id, :symbol, :side, :quantity, :price, :status, :executed_at, :created_at ])
    }, status: :created)
  end

  def cancel
    order = current_user.orders.find(params[:id])
    authorize order

    order.cancel!

    AuditLog.log(
      user: current_user,
      action: "cancel_order",
      auditable: order,
      metadata: {
        symbol: order.symbol,
        side: order.side,
        quantity: order.quantity.to_f,
        price: order.price.to_f
      }
    )

    render_success({
      message: "訂單已取消",
      order: {
        id: order.id,
        status: order.status
      }
    })
  rescue StandardError => e
    render_error(e.message, status: :unprocessable_content)
  end

  private
  def order_params
    params.require(:order).permit(:symbol, :side, :quantity, :price)
  end
end
