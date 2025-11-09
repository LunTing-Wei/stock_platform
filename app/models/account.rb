class Account < ApplicationRecord
  belongs_to :user
  # 禁止刪除有交易記錄的帳戶
  has_many :transactions, dependent: :restrict_with_error

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :locked_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD TWD] }

  # 可用餘額
  def available_balance
    balance - locked_balance
  end

  # 鎖定金額（掛單時用）
  def lock_funds!(amount)
    raise ArgumentError, "鎖定金額必須大於 0" if amount <= 0
    raise InsufficientFundsError, "可用餘額不足" if available_balance < amount

    self.locked_balance += amount
    save!
  end

  # 解鎖金額（取消掛單時用）
  def unlock_funds!(amount)
    raise ArgumentError, "解鎖金額必須大於 0" if amount <= 0
    raise ArgumentError, "鎖定餘額不足" if locked_balance < amount

    self.locked_balance -= amount
    save!
  end

  # 出帳 （買進時用）
  def debit!(amount, transaction_type:, description: nil, transactionable: nil)
    raise ArgumentError, "扣款金額必須大於 0" if amount <= 0
    raise InsufficientFundsError, "餘額不足" if balance < amount

    self.balance -= amount
    save!

    create_transaction!(
      amount: -amount,  # 負數表示扣款
      transaction_type: transaction_type,
      description: description,
      transactionable: transactionable
    )
  end

  # 入帳（賣出時用）
  def credit!(amount, transaction_type:, description: nil, transactionable: nil)
    raise ArgumentError, "入帳金額必須大於 0" if amount <= 0

    self.balance += amount
    save!

    create_transaction!(
      amount: amount,  # 正數表示入帳
      transaction_type: transaction_type,
      description: description,
      transactionable: transactionable
    )
  end

  private
  def create_transaction!(amount:, transaction_type:, description:, transactionable:)
    transactions.create!(
      user: user,
      amount: amount,
      balance_after: balance,  # 記錄交易後的餘額
      transaction_type: transaction_type,
      description: description,
      transactionable: transactionable
    )
  end

  class InsufficientFundsError < StandardError; end
end
