class AllowNullExecutedAtInOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_null :orders, :executed_at, true
  end
end
