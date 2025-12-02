class AddLockVersionToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :lock_version, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        Account.update_all(lock_version: 0)
      end

      dir.down do
      end
    end
  end
end
