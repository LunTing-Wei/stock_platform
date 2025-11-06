class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.decimal :quantity, precision: 18, scale: 8, default: 0, null: false
      t.decimal :average_cost, precision: 18, scale: 8, default: 0, null: false

      t.timestamps
    end

    add_index :positions, [ :user_id, :symbol ], unique: true
  end
end
