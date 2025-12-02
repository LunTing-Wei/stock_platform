class CreateDailyPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_prices do |t|
      t.string :symbol, null: false
      t.date :date, null: false
      t.decimal :open, precision: 10, scale: 2, null: false
      t.decimal :high, precision: 10, scale: 2, null: false
      t.decimal :low, precision: 10, scale: 2, null: false
      t.decimal :close, precision: 10, scale: 2, null: false
      t.bigint :volume, default: 0, null: false

      t.timestamps
    end

    add_index :daily_prices, [ :symbol, :date ], unique: true

    add_index :daily_prices, :date
  end
end
