class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :transactionable, polymorphic: true, optional: true

  enum :transaction_type, {
    deposit: 0,
    withdraw: 1,
    buy: 2,
    sell: 3,
    fee: 4,
    dividend: 5,
    adjustment: 6
  }

  validates :amount, presence: true, numericality: true
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_type, presence: true

  scope :credits, -> { where("amount > 0") }
  scope :debits, -> { where("amount < 0") }

  # 禁止修改和刪除（交易記錄是不可變的）
  before_update :prevent_update
  before_destroy :prevent_destroy

  private

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, "交易記錄不可修改"
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "交易記錄不可刪除"
  end
end
