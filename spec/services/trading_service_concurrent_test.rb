require 'rails_helper'

RSpec.describe TradingService, '並發控制驗證' do
  let(:user) { create(:user) }
  let(:account) { user.account }

  before do
    # 設置足夠的初始餘額 (考慮手續費)
    account.update!(balance: 100000)
  end

  describe '並發買入驗證' do
    it '多個線程同時買入不應該導致數據不一致' do
      threads = []

      # 5 個線程同時買入
      5.times do
        threads << Thread.new do
          service = TradingService.new(user)
          service.execute_order(
            symbol: 'TEST',
            side: :buy,
            quantity: 10,
            price: 100
          )
        end
      end

      threads.each(&:join)

      # 驗證結果
      user.reload
      position = user.positions.find_by(symbol: 'TEST')

      # 應該有 50 股 (5 次 × 10 股)
      expect(position.quantity).to eq(50)

      # 應該有 5 筆訂單
      expect(user.orders.where(symbol: 'TEST', side: :buy).count).to eq(5)

      # 驗證餘額扣除正確
      # 每次買入: 1000 + 手續費(1元) = 1001
      # 5 次: 5005
      expected_balance = 100000 - 5005
      expect(account.reload.balance).to eq(expected_balance)

      puts "✅ 並發買入測試通過"
      puts "   - 持倉數量: #{position.quantity}"
      puts "   - 訂單數量: #{user.orders.where(symbol: 'TEST', side: :buy).count}"
      puts "   - 餘額: #{account.balance}"
    end
  end

  describe '並發賣出驗證' do
    before do
      # 先買入足夠的持倉
      service = TradingService.new(user)
      service.execute_order(symbol: 'TEST', side: :buy, quantity: 100, price: 100)
      account.reload
    end

    it '多個線程同時賣出不應該超賣' do
      threads = []

      # 5 個線程同時賣出 (共 50 股)
      5.times do
        threads << Thread.new do
          service = TradingService.new(user)
          service.execute_order(
            symbol: 'TEST',
            side: :sell,
            quantity: 10,
            price: 150
          )
        end
      end

      threads.each(&:join)

      # 驗證結果
      user.reload
      position = user.positions.find_by(symbol: 'TEST')

      # 應該剩 50 股 (100 - 50)
      expect(position.quantity).to eq(50)

      # 應該有 5 筆賣出訂單
      expect(user.orders.where(symbol: 'TEST', side: :sell).count).to eq(5)

      puts "✅ 並發賣出測試通過"
      puts "   - 剩餘持倉: #{position.quantity}"
      puts "   - 賣出訂單: #{user.orders.where(symbol: 'TEST', side: :sell).count}"
    end
  end

  describe '並發超賣驗證' do
    before do
      # 只買入 30 股
      service = TradingService.new(user)
      service.execute_order(symbol: 'TEST', side: :buy, quantity: 30, price: 100)
      account.reload
    end

    it '多個線程嘗試超賣時應該正確拋出錯誤' do
      threads = []
      success_count = Concurrent::AtomicFixnum.new(0)
      error_count = Concurrent::AtomicFixnum.new(0)

      # 5 個線程嘗試賣出 10 股 (總共需要 50 股，但只有 30 股)
      5.times do
        threads << Thread.new do
          begin
            service = TradingService.new(user)
            service.execute_order(
              symbol: 'TEST',
              side: :sell,
              quantity: 10,
              price: 150
            )
            success_count.increment
          rescue TradingService::InsufficientPositionError => e
            error_count.increment
          end
        end
      end

      threads.each(&:join)

      # 應該有 3 次成功 (30 股)，2 次失敗
      expect(success_count.value).to eq(3)
      expect(error_count.value).to eq(2)

      # 最終持倉應該為 0 或被刪除
      position = user.positions.find_by(symbol: 'TEST')
      expect(position).to be_nil

      puts "✅ 並發超賣防護測試通過"
      puts "   - 成功賣出: #{success_count.value} 次"
      puts "   - 防止超賣: #{error_count.value} 次"
    end
  end
end
