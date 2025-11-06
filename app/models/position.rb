class Position < ApplicationRecord
  belongs_to :user

  validates :symbol, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :average_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :symbol, uniqueness: { scope: :user_id }
end
