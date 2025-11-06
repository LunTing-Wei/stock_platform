class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.integer :side, null: false
      t.decimal :quantity, precision: 18, scale: 8, null: false
      t.decimal :price, precision: 18, scale: 8, null: false
      t.integer :status, null: false, default: 0
      t.datetime :executed_at, null: false

      t.timestamps
    end

    add_index :orders, :symbol
    add_index :orders, :status
    add_index :orders, :executed_at
    add_index :orders, [ :user_id, :created_at ]
  end
end
