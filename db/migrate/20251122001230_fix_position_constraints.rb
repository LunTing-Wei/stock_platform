class FixPositionConstraints < ActiveRecord::Migration[8.0]
  def up
    remove_check_constraint :positions, name: "average_cost_positive"
    remove_check_constraint :positions, name: "current_price_non_negative_or_null"
    remove_check_constraint :positions, name: "quantity_non_negative"

    change_column_default :positions, :average_cost, from: "0.0", to: nil
    change_column_default :positions, :quantity, from: "0.0", to: nil
    change_column_null :positions, :current_price, false


    add_check_constraint :positions, "average_cost > 0", name: "average_cost_positive"
    add_check_constraint :positions, "current_price >= 0", name: "current_price_non_negative"
    add_check_constraint :positions, "quantity > 0", name: "quantity_positive"
  end

  def down
    remove_check_constraint :positions, name: "average_cost_positive"
    remove_check_constraint :positions, name: "current_price_non_negative"
    remove_check_constraint :positions, name: "quantity_positive"

    change_column_null :positions, :current_price, true
    change_column_default :positions, :average_cost, from: nil, to: "0.0"
    change_column_default :positions, :quantity, from: nil, to: "0.0"

    add_check_constraint :positions, "average_cost > 0", name: "average_cost_positive"
    add_check_constraint :positions, "current_price IS NULL OR current_price >= 0", name: "current_price_non_negative_or_null"
    add_check_constraint :positions, "quantity >= 0", name: "quantity_non_negative"
  end
end
