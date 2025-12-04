class Order < ApplicationRecord
  belongs_to :user

  enum :side, { buy: 0, sell: 1 }
  enum :status, { pending: 0, completed: 1, cancelled: 2 }

  validates :symbol, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  validates :side, presence: true
  validates :status, presence: true

  def execute!
    raise "只能執行 pending 狀態的訂單" unless pending?

    completed!
    update!(executed_at: Time.current)
  end

  def cancel!
    raise "只能取消 pending 狀態的訂單" unless pending?

    cancelled!
  end
end
