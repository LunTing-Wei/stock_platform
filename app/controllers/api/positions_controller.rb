class Api::PositionsController < Api::BaseController
  def index
    positions = current_user.positions
    authorize Position
    positions = positions.where(symbol: params[:symbol]) if params[:symbol].present?
    positions = positions.order(symbol: :asc)
    render_success({
      positions: positions.map { |p| serialize_position(p) },
      summary: calculate_summary(positions)
    })
  end

  def show
    position = current_user.positions.find(params[:id])
    authorize position
    render_success({ position: serialize_position(position) })
  end

  private

  def calculate_summary(positions)
    stats = positions.unscope(:order).pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("SUM(quantity * current_price)"),
      Arel.sql("SUM(quantity * average_cost)")
    )

    total_positions = stats[0] || 0
    total_market_value = (stats[1] || 0).to_f
    total_cost_basis = (stats[2] || 0).to_f

    total_profit_loss = total_market_value - total_cost_basis

    total_profit_loss_percentage = if total_cost_basis.zero?
      0.0
    else
      ((total_profit_loss / total_cost_basis) * 100).round(2)
    end

    {
      total_positions: total_positions,
      total_market_value: total_market_value.round(2),
      total_cost_basis: total_cost_basis.round(2),
      total_profit_loss: total_profit_loss.round(2),
      total_profit_loss_percentage: total_profit_loss_percentage
    }
  end
  def serialize_position(position)
    {
      id: position.id,
      user_id: position.user_id,
      symbol: position.symbol,
      quantity: position.quantity.to_f,
      average_cost: position.average_cost.to_f,
      current_price: position.price.to_f,
      cost_basis: position.cost_basis.to_f,
      market_value: position.market_value.to_f,
      profit_loss: position.unrealized_gain_loss.to_f,
      profit_loss_percentage: position.unrealized_return_rate,
      created_at: position.created_at,
      updated_at: position.updated_at
    }
  end
end
