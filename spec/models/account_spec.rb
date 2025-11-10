require 'rails_helper'

RSpec.describe Account, type: :model do
  let(:user) { create(:user, :with_balance, balance: 10000) }
  let(:account) { user.account }

  describe '#debit!' do
    context '當餘額足夠時' do
      it '應該扣除餘額並建立交易記錄' do
        transaction = account.debit!(
          1000,
          transaction_type: :buy,
          description: "測試扣款"
        )
        expect(account.balance).to eq(9000)

        expect(transaction).to be_persisted  # 確認已存入資料庫
        expect(transaction.amount).to eq(-1000)  # 扣款是負數
        expect(transaction.balance_after).to eq(9000)
        expect(transaction.transaction_type).to eq('buy')
      end
    end

    context '當餘額不足時' do
      it '應該拋出 InsufficientFundsError' do
        expect {
          account.debit!(20000, transaction_type: :buy)
        }.to raise_error(Account::InsufficientFundsError, "餘額不足")
      end

      it '不應該扣除任何餘額' do
        expect {
          account.debit!(20000, transaction_type: :buy)
        }.to raise_error(Account::InsufficientFundsError)

        # 餘額應該保持不變
        expect(account.reload.balance).to eq(10000)
      end
    end
  end

  describe '#credit!' do
    it '應該增加餘額並建立交易記錄' do
      transaction = account.credit!(
        5000,
        transaction_type: :sell,
        description: "測試入帳"
      )

      expect(account.balance).to eq(15000)
      expect(transaction.amount).to eq(5000)  # 入帳是正數
      expect(transaction.balance_after).to eq(15000)
    end
  end
end
