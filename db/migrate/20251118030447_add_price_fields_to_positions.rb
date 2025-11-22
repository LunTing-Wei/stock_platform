class AddPriceFieldsToPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :positions, :current_price, :decimal, precision: 10, scale: 2
    add_column :positions, :price_updated_at, :datetime

    add_index :positions, :price_updated_at
  end
end
