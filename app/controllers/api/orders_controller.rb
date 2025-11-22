class Api::OrdersController < Api::BaseController
  def index
    orders = current_user.orders

    orders = orders.where(symbol: params[:symbol]) if params[:symbol].present?
    orders = orders.where(side: params[:side]) if params[:side].present?
    orders = orders.where(status: params[:status]) if params[:status].present?

    orders = orders.order(created_at: :desc)

    total_count = orders.count

    page = params[:page]&.to_i || 1
    per_page = 20
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

    service = TradingService.new(current_user)

    order = service.execute_order(
      symbol: order_params[:symbol],
      side: order_params[:side].to_sym,
      quantity: order_params[:quantity].to_i,
      price: order_params[:price].to_f
    )
    render_success({
      order: order.as_json(only: [ :id, :symbol, :side, :quantity, :price, :status, :executed_at, :created_at ])
    }, status: :created)
  end

  private
  def order_params
    params.require(:order).permit(:symbol, :side, :quantity, :price)
  end
end
