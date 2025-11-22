class Api::PositionsController < Api::BaseController
  def index
    positions = current_user.positions
    positions = positions.where(symbol: params[:symbol]) if params[:symbol].present?
    positions = positions.order(symbol: :asc)
    render_success({
      positions: positions.as_json,
      summary: calculate_summary(positions)
    })
  end

  def show
    position = current_user.positions.find(params[:id])
    render_success(position: position.as_json)
  end

  private

  def calculate_summary(positions)
    {
      total_positions: positions.size,
      total_market_value: positions.sum(&:market_value).round(2),
      total_cost_basis: positions.sum(&:cost_basis).round(2),
      total_profit_loss: positions.sum(&:unrealized_gain_loss).round(2),
      total_profit_loss_percentage: calculate_total_return_rate(positions)
    }
  end

  def calculate_total_return_rate(positions)
    total_cost = positions.sum(&:cost_basis)
    return 0.0 if total_cost.zero?

    total_market_value = positions.sum(&:market_value)
    ((total_market_value - total_cost)/ total_cost * 100).round(2)
  end
end
