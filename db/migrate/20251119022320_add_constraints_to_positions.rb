class AddConstraintsToPositions < ActiveRecord::Migration[8.0]
  def change
    # 持倉數量不能為負數
    add_check_constraint :positions,
    "quantity >= 0::numeric",
    name: "quantity_non_negative"

    # 平均成本必須大於 0
    add_check_constraint :positions,
      "average_cost > 0::numeric",
      name: "average_cost_positive"

    # 當前價格如果不是 NULL，就必須非負
    add_check_constraint :positions,
      "current_price IS NULL OR current_price >= 0::numeric",
      name: "current_price_non_negative_or_null"
  end
end
