class Account < ApplicationRecord
  belongs_to :user
  # 禁止刪除有交易記錄的帳戶
  has_many :transactions, dependent: :restrict_with_error

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD TWD] }

  # 樂觀鎖最大重試次數
  MAX_LOCK_RETRIES = 3


  # 出帳 （買進時用）
  def debit!(amount, transaction_type:, description: nil, transactionable: nil)
    raise ArgumentError, "扣款金額必須大於 0" if amount <= 0

    with_lock_retry do
      reload

      raise InsufficientFundsError, "餘額不足" if balance < amount

      self.balance -= amount
      save!

      create_transaction!(
        amount: -amount,
        transaction_type: transaction_type,
        description: description,
        transactionable: transactionable
      )
    end
  end

  # 入帳（賣出時用）
  def credit!(amount, transaction_type:, description: nil, transactionable: nil)
    raise ArgumentError, "入帳金額必須大於 0" if amount <= 0

    with_lock_retry do
      reload
      self.balance += amount
      save!

      create_transaction!(
        amount: amount,  # 正數表示入帳
        transaction_type: transaction_type,
        description: description,
        transactionable: transactionable
      )
    end
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

  def with_lock_retry(retries: MAX_LOCK_RETRIES, &block)
    attempts = 0

    begin
      attempts += 1
      yield
    rescue ActiveRecord::StaleObjectError => e
      if attempts < retries
        sleep(0.01 * (2 ** attempts))
        retry
      else
        raise e
      end
    end
  end

  class InsufficientFundsError < StandardError; end
end
