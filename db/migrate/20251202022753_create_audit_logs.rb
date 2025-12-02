class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.jsonb :metadata, default: {}
      t.string :ip_address

      t.timestamps
    end

    add_index :audit_logs, [ :user_id, :created_at ]
    add_index :audit_logs, [ :auditable_type, :auditable_id ]
    add_index :audit_logs, :action
  end
end
