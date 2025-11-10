require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:user) { create(:user, :with_balance, balance: 10000) }
  let(:account) { user.account }

  let(:transaction) do
    account.debit!(
      1000,
      transaction_type: :buy,
      description: "測試交易"
    )
  end

  describe '不可變性' do
    context '當嘗試修改交易記錄時' do
      it '應該拋出 ReadOnlyRecord 錯誤' do
        expect {
          transaction.update!(amount: 999999)
      }.to raise_error(ActiveRecord::ReadOnlyRecord, "交易記錄不可修改")
      end

      it '交易金額應該保持不變' do
        begin
          transaction.update!(amount: 999999)
        rescue ActiveRecord::ReadOnlyRecord
        end
        expect(transaction.reload.amount).to eq(-1000)
      end
    end
    context '當嘗試刪除交易記錄時' do
      it '應該拋出 ReadOnlyRecord 錯誤' do
        expect {
          transaction.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord, "交易記錄不可刪除")
      end

      it '交易記錄應該仍然存在於資料庫' do
        begin
            transaction.destroy!
        rescue ActiveRecord::ReadOnlyRecord
        end

        expect(Transaction.exists?(transaction.id)).to be true
      end
    end
  end

  describe '交易記錄欄位驗證' do
    it '應該正確記錄所有必要欄位' do
      expect(transaction.user).to eq(user)
      expect(transaction.account).to eq(account)
      expect(transaction.amount).to eq(-1000)
      expect(transaction.balance_after).to eq(9000)
      expect(transaction.transaction_type).to eq('buy')
      expect(transaction.description).to eq("測試交易")
    end

    it 'amount 應該是負數（扣款）' do
      expect(transaction.amount).to be < 0
    end

    it 'balance_after 應該等於當前帳戶餘額' do
      expect(transaction.balance_after).to eq(account.balance)
    end
  end

  describe 'scope 篩選器' do
    before do
      account.debit!(500, transaction_type: :buy, description: "買入1")
      account.credit!(300, transaction_type: :sell, description: "賣出1")
      account.debit!(200, transaction_type: :buy, description: "買入2")
    end

    it 'credits scope 應該只回傳入帳記錄' do
      credits = account.transactions.credits

      expect(credits.count).to eq(1)
      expect(credits.first.amount).to be > 0
      expect(credits.first.transaction_type).to eq('sell')
    end

    it 'debits scope 應該只回傳扣款記錄' do
      debits = account.transactions.debits

      expect(debits.count).to eq(2)
      debits.each do |debit|
        expect(debit.amount).to be < 0
      end
    end
  end
end
