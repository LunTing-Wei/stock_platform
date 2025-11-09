class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :transactionable, polymorphic: true, null: true


      t.integer :transaction_type, null: false
      t.decimal :amount, precision: 18, scale: 8, null: false
      t.decimal :balance_after, precision: 18, scale: 8, null: false
      t.text :description

      t.timestamps
    end

    add_index :transactions, [ :user_id, :created_at ]

    add_index :transactions, [ :account_id, :created_at ]

    add_index :transactions, [ :transactionable_type, :transactionable_id, :created_at ],
              name: 'index_transactions_on_transactionable_and_created_at'
  end
end
