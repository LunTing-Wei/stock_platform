class BackfillCurrentPriceForPositions < ActiveRecord::Migration[8.0]
  def up
    Position.where(current_price: nil).find_each do |position|
      position.update_column(:current_price, position.average_cost)
    end
  end

  def down
  end
end
