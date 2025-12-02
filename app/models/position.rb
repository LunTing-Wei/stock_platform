class Position < ApplicationRecord
  belongs_to :user

  validates :symbol, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :average_cost, numericality: { greater_than: 0 }
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }
  validates :symbol, uniqueness: { scope: :user_id }

  before_validation :set_default_current_price, on: :create

  # 股價更新間隔（5 分鐘）
  PRICE_REFRESH_INTERVAL = 5.minutes

  def price
    current_price
  end

  def unrealized_gain_loss
    market_value - cost_basis
  end

  def unrealized_return_rate
    return 0.0 if average_cost.zero?
    ((price - average_cost) / average_cost * 100).round(2)
  end

  def market_value
    quantity * price
  end

  def cost_basis
    quantity * average_cost
  end

  def as_json(options = {})
    super(options).merge(
      "current_price" => price.to_f,
      "cost_basis" => cost_basis.to_f,
      "market_value" => market_value.to_f,
      "profit_loss" => unrealized_gain_loss.to_f,
      "profit_loss_percentage" => unrealized_return_rate
    )
  end

  private

  def set_default_current_price
    self.current_price ||= average_cost
  end
end
