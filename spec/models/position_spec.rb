require 'rails_helper'

RSpec.describe Position, type: :model do
  let(:user) { create(:user, :with_balance, balance: 10000) }

  describe '驗證規則' do
    it '應該屬於一個用戶' do
      position = Position.new(symbol: 'AAPL', quantity: 100, average_cost: 50)
      expect(position).not_to be_valid
      expect(position.errors[:user]).to be_present
    end

    it 'symbol 不能為空' do
      position = user.positions.build(quantity: 100, average_cost: 50)
      expect(position).not_to be_valid
      expect(position.errors[:symbol]).to be_present
    end

    it 'quantity 必須大於等於 0' do
      position = user.positions.build(symbol: 'AAPL', quantity: -1, average_cost: 50)
      expect(position.valid?).to be false
    end

    it 'average_cost 必須大於等於 0' do
      position = user.positions.build(symbol: 'AAPL', quantity: 100, average_cost: -1)
      expect(position.valid?).to be false
    end

    it '同一個用戶不能有重複的 symbol' do
      user.positions.create!(symbol: 'AAPL', quantity: 100, average_cost: 50)

      duplicate_position = user.positions.build(symbol: 'AAPL', quantity: 50, average_cost: 60)
      expect(duplicate_position).not_to be_valid
      expect(duplicate_position.errors[:symbol]).to be_present
    end

    it '不同用戶可以持有相同的 symbol' do
      user1 = create(:user, :with_balance, balance: 10000)
      user2 = create(:user, :with_balance, balance: 10000)

      position1 = user1.positions.create!(symbol: 'AAPL', quantity: 100, average_cost: 50)
      position2 = user2.positions.create!(symbol: 'AAPL', quantity: 50, average_cost: 60)

      expect(position1).to be_persisted
      expect(position2).to be_persisted
    end
  end

  describe '持倉資料' do
    it '應該正確儲存持倉資訊' do
      position = user.positions.create!(
        symbol: 'AAPL',
        quantity: 100,
        average_cost: 50.5
      )

      expect(position.symbol).to eq('AAPL')
      expect(position.quantity).to eq(100)
      expect(position.average_cost).to eq(50.5)
      expect(position.user).to eq(user)
    end
  end

  describe '持倉計算（透過 TradingService 測試）' do
    it '首次買入應該建立新持倉' do
      service = TradingService.new(user)

      service.execute_order(
        symbol: 'AAPL',
        side: :buy,
        quantity: 100,
        price: 50
      )

      position = user.positions.find_by(symbol: 'AAPL')
      expect(position.quantity).to eq(100)
      expect(position.average_cost).to eq(50)
    end

    it '加碼買入應該更新平均成本' do
      service = TradingService.new(user)
      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 100, price: 50)

      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 50, price: 60)

      position = user.positions.find_by(symbol: 'AAPL')

      # 總成本 = 100*50 + 50*60 = 5000 + 3000 = 8000
      # 總股數 = 100 + 50 = 150
      # 平均成本 = 8000 / 150 = 53.333...
      expect(position.quantity).to eq(150)
      expect(position.average_cost.to_f).to be_within(0.01).of(53.33)
    end

    it '賣出部分持倉應該減少數量但不改變平均成本' do
      service = TradingService.new(user)


      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 100, price: 50)

      position = user.positions.find_by(symbol: 'AAPL')
      original_avg_cost = position.average_cost

      service.execute_order(symbol: 'AAPL', side: :sell, quantity: 50, price: 60)

      position.reload
      expect(position.quantity).to eq(50)
      expect(position.average_cost).to eq(original_avg_cost)  # 平均成本不變
    end

    it '全部賣出應該刪除持倉' do
      service = TradingService.new(user)
      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 100, price: 50)
      service.execute_order(symbol: 'AAPL', side: :sell, quantity: 100, price: 60)

      # 持倉應該被刪除
      expect(user.positions.find_by(symbol: 'AAPL')).to be_nil
    end
  end
end
