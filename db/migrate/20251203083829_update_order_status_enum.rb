class UpdateOrderStatusEnum < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE orders SET status = 1 WHERE status = 0;
    SQL
  end

  def down
    execute <<-SQL
      UPDATE orders SET status = 0 WHERE status = 1;
    SQL
  end
end
