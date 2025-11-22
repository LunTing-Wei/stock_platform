class Order < ApplicationRecord
  belongs_to :user

  enum :side, { buy: 0, sell: 1 }
  enum :status, { completed: 0 }

  validates :symbol, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  validates :side, presence: true
  validates :status, presence: true
  validates :executed_at, presence: true
end
