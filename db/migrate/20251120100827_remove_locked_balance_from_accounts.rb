class RemoveLockedBalanceFromAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_column :accounts, :locked_balance, :decimal
  end
end
