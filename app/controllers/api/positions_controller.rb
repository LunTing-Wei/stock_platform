class Api::PositionsController < Api::BaseController
  def index
    positions = current_user.positions
    positions = positions.where(symbol: params[:symbol]) if params[:symbol].present?
    positions = positions.order(symbol: :asc)
    positions_data = positions.map do |position|
      current_price = mock_current_price(position.average_cost)
      market_value = position.quantity * current_price
      cost_basis = position.quantity * position.average_cost
      profit_loss = market_value - cost_basis
      profit_loss_percentage = cost_basis > 0 ? (profit_loss / cost_basis * 100) : 0
      {
        id: position.id,
        symbol: position.symbol,
        quantity: position.quantity.to_f,
        average_cost: position.average_cost.to_f,
        current_price: current_price.to_f,
        market_value: market_value.to_f,
        cost_basis: cost_basis.to_f,
        profit_loss: profit_loss.to_f,
        profit_loss_percentage: profit_loss_percentage.round(2),
        created_at: position.created_at,
        updated_at: position.updated_at
      }
    end

    total_market_value = positions_data.sum { |p| p[:market_value] }
    total_cost_basis = positions_data.sum { |p| p[:cost_basis] }
    total_profit_loss = total_market_value - total_cost_basis
    total_profit_loss_percentage = total_cost_basis > 0 ? (total_profit_loss / total_cost_basis * 100) : 0

    render_success({
      positions: positions_data,
      summary: {
        total_positions: positions.count,
        total_market_value: total_market_value.round(2),
        total_cost_basis: total_cost_basis.round(2),
        total_profit_loss: total_profit_loss.round(2),
        total_profit_loss_percentage: total_profit_loss_percentage.round(2)
      }
    })
  end

  def show
    position = current_user.positions.find(params[:id])
    current_price = mock_current_price(position.average_cost)
    market_value = position.quantity * current_price
    cost_basis = position.quantity * position.average_cost
    profit_loss = market_value - cost_basis
    profit_loss_percentage = cost_basis > 0 ? (profit_loss / cost_basis * 100) : 0

    render_success({
      position: {
        id: position.id,
        symbol: position.symbol,
        quantity: position.quantity.to_f,
        average_cost: position.average_cost.to_f,
        current_price: current_price.to_f,
        market_value: market_value.to_f,
        cost_basis: cost_basis.to_f,
        profit_loss: profit_loss.to_f,
        profit_loss_percentage: profit_loss_percentage.round(2),
        created_at: position.created_at,
        updated_at: position.updated_at
      }
    })
  end

  private

  def mock_current_price(average_cost)
    variation = rand(-0.10..0.10)
    new_price = average_cost * (1 + variation)
    new_price.round(2)
  end
end
