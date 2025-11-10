require 'rails_helper'

RSpec.describe TradingService do
  let(:user) { create(:user, :with_balance, balance: 10000) }
  let(:service) { TradingService.new(user) }

  describe '#initialize' do
    it '應該初始化 service' do
      expect(service).to be_a(TradingService)
    end
  end

  describe '#execute_order 買入' do
    context '當餘額充足時' do
      it '應該成功買入並建立 Order' do
        order = service.execute_order(
          symbol: 'AAPL',
          side: :buy,
          quantity: 10,
          price: 100
        )

        expect(order).to be_persisted
        expect(order.symbol).to eq('AAPL')
        expect(order.side).to eq('buy')
        expect(order.quantity).to eq(10)
        expect(order.price).to eq(100)
        expect(order.status).to eq('completed')
        expect(order.executed_at).to be_present
      end

      it '應該扣除帳戶餘額' do
        initial_balance = user.account.balance

        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)

        user.account.reload
        expect(user.account.balance).to eq(initial_balance - 1000)
      end

      it '應該建立 Transaction 記錄' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
        }.to change { user.account.transactions.count }.by(1)

        transaction = user.account.transactions.last
        expect(transaction.amount).to eq(-1000)
        expect(transaction.transaction_type).to eq('buy')
        expect(transaction.balance_after).to eq(9000)
      end

      it '應該建立或更新 Position' do
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)

        position = user.positions.find_by(symbol: 'AAPL')
        expect(position).to be_present
        expect(position.quantity).to eq(10)
        expect(position.average_cost).to eq(100)
      end

      it '多次買入應該累加持倉並更新平均成本' do
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 200)

        position = user.positions.find_by(symbol: 'AAPL')
        expect(position.quantity).to eq(20)
        # (10*100 + 10*200) / 20 = 3000 / 20 = 150
        expect(position.average_cost).to eq(150)
      end
    end

    context '當餘額不足時' do
      it '應該拋出 InsufficientFundsError' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :buy, quantity: 200, price: 100)
        }.to raise_error(TradingService::InsufficientFundsError)
      end

      it '不應該建立 Order' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :buy, quantity: 200, price: 100)
        }.to raise_error(TradingService::InsufficientFundsError)

        expect(user.orders.count).to eq(0)
      end

      it '不應該扣除餘額' do
        initial_balance = user.account.balance

        expect {
          service.execute_order(symbol: 'AAPL', side: :buy, quantity: 200, price: 100)
        }.to raise_error(TradingService::InsufficientFundsError)

        expect(user.account.reload.balance).to eq(initial_balance)
      end

      it '不應該建立 Position' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :buy, quantity: 200, price: 100)
        }.to raise_error(TradingService::InsufficientFundsError)

        expect(user.positions.count).to eq(0)
      end
    end
  end

  describe '#execute_order 賣出' do
    before do
      # 先買入一些持倉
      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
    end

    context '當持倉充足時' do
      it '應該成功賣出並建立 Order' do
        order = service.execute_order(
          symbol: 'AAPL',
          side: :sell,
          quantity: 5,
          price: 150
        )

        expect(order).to be_persisted
        expect(order.symbol).to eq('AAPL')
        expect(order.side).to eq('sell')
        expect(order.quantity).to eq(5)
        expect(order.price).to eq(150)
        expect(order.status).to eq('completed')
      end

      it '應該增加帳戶餘額' do
        # 買入後餘額：10000 - 1000 = 9000
        balance_after_buy = user.account.reload.balance

        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)

        user.account.reload
        expect(user.account.balance).to eq(balance_after_buy + 750)
      end

      it '應該建立 Transaction 記錄' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)
        }.to change { user.account.transactions.count }.by(1)

        transaction = user.account.transactions.last
        expect(transaction.amount).to eq(750)
        expect(transaction.transaction_type).to eq('sell')
      end

      it '應該減少持倉數量' do
        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)

        position = user.positions.find_by(symbol: 'AAPL')
        expect(position.quantity).to eq(5)
      end

      it '賣出不應該改變平均成本' do
        position = user.positions.find_by(symbol: 'AAPL')
        original_avg_cost = position.average_cost

        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)

        position.reload
        expect(position.average_cost).to eq(original_avg_cost)
      end

      it '全部賣出應該刪除持倉' do
        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 10, price: 150)

        expect(user.positions.find_by(symbol: 'AAPL')).to be_nil
      end
    end

    context '當持倉不足時' do
      it '應該拋出 InsufficientPositionError' do
        expect {
          service.execute_order(symbol: 'AAPL', side: :sell, quantity: 20, price: 150)
        }.to raise_error(TradingService::InsufficientPositionError)
      end

      it '不應該建立 Order' do
        initial_order_count = user.orders.count

        expect {
          service.execute_order(symbol: 'AAPL', side: :sell, quantity: 20, price: 150)
        }.to raise_error(TradingService::InsufficientPositionError)

        expect(user.orders.count).to eq(initial_order_count)
      end

      it '不應該改變帳戶餘額' do
        initial_balance = user.account.reload.balance

        expect {
          service.execute_order(symbol: 'AAPL', side: :sell, quantity: 20, price: 150)
        }.to raise_error(TradingService::InsufficientPositionError)

        expect(user.account.reload.balance).to eq(initial_balance)
      end
    end

    context '當沒有該持倉時' do
      it '應該拋出 InsufficientPositionError' do
        expect {
          service.execute_order(symbol: 'TSLA', side: :sell, quantity: 5, price: 150)
        }.to raise_error(TradingService::InsufficientPositionError)
      end
    end
  end

  describe '參數驗證' do
    it 'symbol 為空時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: '', side: :buy, quantity: 10, price: 100)
      }.to raise_error(ArgumentError, "股票代碼不能為空")
    end

    it 'quantity 為 0 時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 0, price: 100)
      }.to raise_error(ArgumentError, "數量必須大於 0")
    end

    it 'quantity 為負數時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: -10, price: 100)
      }.to raise_error(ArgumentError, "數量必須大於 0")
    end

    it 'price 為 0 時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 0)
      }.to raise_error(ArgumentError, "價格必須大於 0")
    end

    it 'price 為負數時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: -100)
      }.to raise_error(ArgumentError, "價格必須大於 0")
    end

    it 'side 無效時應該拋出 ArgumentError' do
      expect {
        service.execute_order(symbol: 'AAPL', side: :invalid, quantity: 10, price: 100)
      }.to raise_error(ArgumentError, /無效的交易方向/)
    end
  end

  describe 'Transaction 原子性' do
    it '當發生錯誤時應該 rollback 所有變更' do
      initial_balance = user.account.balance
      initial_transaction_count = user.account.transactions.count

      # 故意觸發錯誤（餘額不足）
      expect {
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 200, price: 100)
      }.to raise_error(TradingService::InsufficientFundsError)

      # 所有資料都應該回復
      expect(user.account.reload.balance).to eq(initial_balance)
      expect(user.account.transactions.count).to eq(initial_transaction_count)
      expect(user.orders.count).to eq(0)
      expect(user.positions.count).to eq(0)
    end
  end

  describe '並發安全性測試' do
    context '多執行緒同時買入' do
      it '應該正確處理並發買入請求' do
        threads = []
        buy_count = 5  # 5 個執行緒

        # 每個執行緒買入 $500
        buy_count.times do
          threads << Thread.new do
            service = TradingService.new(user)
            service.execute_order(
              symbol: 'AAPL',
              side: :buy,
              quantity: 5,
              price: 100
            )
          end
        end

        # 等待所有執行緒完成
        threads.each(&:join)

        # 驗證結果
        user.account.reload
        position = user.positions.find_by(symbol: 'AAPL')

        # 總共買入 5 次，每次 5 股 @ $100 = $500
        # 總花費：$2500
        expect(user.account.balance).to eq(10000 - 2500)
        expect(position.quantity).to eq(25)
        expect(position.average_cost).to eq(100)

        # 確認建立了 5 筆訂單
        expect(user.orders.count).to eq(5)

        # 確認建立了 5 筆交易記錄
        expect(user.account.transactions.count).to eq(5)
      end
    end

    context '多執行緒同時賣出' do
      before do
        # 先買入一些持倉
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 100, price: 100)
      end

      it '應該正確處理並發賣出請求' do
        threads = []
        sell_count = 5

        # 每個執行緒賣出 10 股
        sell_count.times do
          threads << Thread.new do
            service = TradingService.new(user)
            service.execute_order(
              symbol: 'AAPL',
              side: :sell,
              quantity: 10,
              price: 150
            )
          end
        end

        threads.each(&:join)

        # 驗證結果
        user.account.reload
        position = user.positions.find_by(symbol: 'AAPL')

        # 初始餘額：10000
        # 買入花費：-10000 (100股 @ $100)
        # 賣出收入：+7500 (50股 @ $150)
        # 最終餘額：7500
        expect(user.account.balance).to eq(7500)

        # 剩餘持倉：100 - 50 = 50
        expect(position.quantity).to eq(50)

        # 平均成本不變
        expect(position.average_cost).to eq(100)
      end

      it '當多個執行緒嘗試超賣時應該拋出錯誤' do
        threads = []
        errors = []

        # 5 個執行緒，每個嘗試賣出 30 股（總共 150 股，但只有 100 股）
        5.times do
          threads << Thread.new do
            begin
              service = TradingService.new(user)
              service.execute_order(
                symbol: 'AAPL',
                side: :sell,
                quantity: 30,
                price: 150
              )
            rescue TradingService::InsufficientPositionError => e
              errors << e
            end
          end
        end

        threads.each(&:join)

        # 應該有一些執行緒成功，一些失敗
        successful_orders = user.orders.where(side: :sell).count

        # 100 股 / 30 股 = 最多 3 次成功（90 股），剩 10 股不夠賣
        expect(successful_orders).to be <= 3
        expect(errors.size).to be > 0

        # 驗證最終持倉不會是負數
        position = user.positions.find_by(symbol: 'AAPL')
        if position
          expect(position.quantity).to be >= 0
        end
      end
    end

    context '混合並發操作' do
      before do
        # 先買入一些持倉
        service.execute_order(symbol: 'AAPL', side: :buy, quantity: 50, price: 100)
      end

      it '應該正確處理同時買入和賣出' do
        threads = []

        # 3 個執行緒買入
        3.times do
          threads << Thread.new do
            service = TradingService.new(user)
            service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
          end
        end

        # 2 個執行緒賣出
        2.times do
          threads << Thread.new do
            service = TradingService.new(user)
            service.execute_order(symbol: 'AAPL', side: :sell, quantity: 10, price: 150)
          end
        end

        threads.each(&:join)

        # 驗證最終資料一致性
        user.account.reload
        position = user.positions.find_by(symbol: 'AAPL')

        # 初始：50 股
        # 買入：+30 股
        # 賣出：-20 股
        # 最終：60 股
        expect(position.quantity).to eq(60)

        # 驗證交易記錄數量正確
        # 初始買入 1 筆 + 3 筆買入 + 2 筆賣出 = 6 筆
        expect(user.account.transactions.count).to eq(6)
      end
    end
  end
end
