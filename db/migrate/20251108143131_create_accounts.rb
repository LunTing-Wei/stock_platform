class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.decimal :balance, precision: 18, scale: 8, default: 0, null: false
      t.decimal :locked_balance, precision: 18, scale: 8, default: 0, null: false
      t.string :currency, null: false, default: 'USD'

      t.timestamps
    end

    # 資料庫層級的約束：餘額不能是負數(PostgreSQL)
    add_check_constraint :accounts, "balance >= 0", name: "balance_non_negative"
    add_check_constraint :accounts, "locked_balance >= 0", name: "locked_balance_non_negative"
  end
end
