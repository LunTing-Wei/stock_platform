require 'rails_helper'

RSpec.describe Account, '樂觀鎖測試' do
  let(:user) { create(:user) }
  let(:account) { user.account }

  before do
    # 使用 update_column 不觸發樂觀鎖版本增加
    account.update_column(:balance, 10000)
  end

  describe '樂觀鎖基本功能' do
    it 'Account 應該有 lock_version 欄位' do
      expect(account).to respond_to(:lock_version)
      expect(account.lock_version).to eq(0)
    end

    it '每次更新應該增加 lock_version' do
      expect {
        account.update!(balance: 9000)
      }.to change { account.lock_version }.from(0).to(1)
    end

    it '版本不匹配時應該拋出 StaleObjectError' do
      # 讀取兩個相同的實例
      account1 = Account.find(account.id)
      account2 = Account.find(account.id)

      # account1 先更新
      account1.balance = 9000
      account1.save!

      # account2 嘗試更新 (版本已過期)
      account2.balance = 8000
      expect {
        account2.save!
      }.to raise_error(ActiveRecord::StaleObjectError)
    end
  end

  describe '#debit! 並發安全' do
    it '多個線程同時扣款應該正確處理' do
      threads = []

      # 5 個線程同時扣款 1000
      5.times do |i|
        threads << Thread.new do
          # 每個線程使用獨立的 account 實例
          acc = Account.find(account.id)
          acc.debit!(
            1000,
            transaction_type: :adjustment,
            description: "測試扣款 #{i}"
          )
        end
      end

      threads.each(&:join)

      # 驗證最終餘額
      account.reload
      expect(account.balance).to eq(5000)  # 10000 - 5*1000

      # 驗證 lock_version 增加了 5 次
      expect(account.lock_version).to eq(5)

      # 驗證有 5 筆交易記錄
      expect(account.transactions.count).to eq(5)

      puts "✅ debit! 並發測試通過"
      puts "   - 最終餘額: #{account.balance}"
      puts "   - Lock version: #{account.lock_version}"
      puts "   - 交易記錄: #{account.transactions.count}"
    end

    it '並發扣款時餘額不足應該正確拋出錯誤' do
      threads = []
      success_count = Concurrent::AtomicFixnum.new(0)
      error_count = Concurrent::AtomicFixnum.new(0)

      # 5 個線程嘗試扣款 3000 (總共需要 15000，但只有 10000)
      5.times do |i|
        threads << Thread.new do
          begin
            acc = Account.find(account.id)
            acc.debit!(
              3000,
              transaction_type: :adjustment,
              description: "測試扣款 #{i}"
            )
            success_count.increment
          rescue Account::InsufficientFundsError => e
            error_count.increment
          end
        end
      end

      threads.each(&:join)

      # 應該有 3 次成功，2 次失敗
      expect(success_count.value).to eq(3)
      expect(error_count.value).to eq(2)

      # 最終餘額應該是 1000
      account.reload
      expect(account.balance).to eq(1000)

      puts "✅ debit! 餘額不足防護測試通過"
      puts "   - 成功扣款: #{success_count.value} 次"
      puts "   - 餘額不足: #{error_count.value} 次"
      puts "   - 最終餘額: #{account.balance}"
    end
  end

  describe '#credit! 並發安全' do
    it '多個線程同時入帳應該正確處理' do
      threads = []

      # 5 個線程同時入帳 500
      5.times do |i|
        threads << Thread.new do
          acc = Account.find(account.id)
          acc.credit!(
            500,
            transaction_type: :adjustment,
            description: "測試入帳 #{i}"
          )
        end
      end

      threads.each(&:join)

      # 驗證最終餘額
      account.reload
      expect(account.balance).to eq(12500)  # 10000 + 5*500

      # 驗證 lock_version
      expect(account.lock_version).to eq(5)

      puts "✅ credit! 並發測試通過"
      puts "   - 最終餘額: #{account.balance}"
      puts "   - Lock version: #{account.lock_version}"
    end
  end

  describe '混合並發操作' do
    it '同時進行入帳和扣款應該正確處理' do
      threads = []

      # 3 個線程入帳 1000
      3.times do |i|
        threads << Thread.new do
          acc = Account.find(account.id)
          acc.credit!(
            1000,
            transaction_type: :adjustment,
            description: "測試入帳 #{i}"
          )
        end
      end

      # 2 個線程扣款 500
      2.times do |i|
        threads << Thread.new do
          acc = Account.find(account.id)
          acc.debit!(
            500,
            transaction_type: :adjustment,
            description: "測試扣款 #{i}"
          )
        end
      end

      threads.each(&:join)

      # 驗證最終餘額
      # 10000 + 3*1000 - 2*500 = 12000
      account.reload
      expect(account.balance).to eq(12000)

      # 驗證 lock_version
      expect(account.lock_version).to eq(5)

      # 驗證交易記錄數量
      expect(account.transactions.count).to eq(5)

      puts "✅ 混合並發操作測試通過"
      puts "   - 最終餘額: #{account.balance}"
      puts "   - Lock version: #{account.lock_version}"
      puts "   - 交易記錄: #{account.transactions.count}"
    end
  end

  describe '重試機制' do
    it '應該在版本衝突時自動重試' do
      # 模擬重試場景
      retry_count = 0

      allow_any_instance_of(Account).to receive(:save!) do |account_instance|
        retry_count += 1

        if retry_count == 1
          # 第一次調用時拋出 StaleObjectError
          raise ActiveRecord::StaleObjectError.new(account_instance, "update")
        else
          # 第二次調用時成功
          account_instance.update_column(:balance, account_instance.balance)
          account_instance.update_column(:lock_version, account_instance.lock_version + 1)
        end
      end

      # 執行 debit!
      expect {
        account.debit!(
          100,
          transaction_type: :adjustment,
          description: "測試重試"
        )
      }.not_to raise_error

      # 驗證 save! 被調用了 2 次 (1 次失敗 + 1 次成功)
      expect(retry_count).to eq(2)

      puts "✅ 重試機制測試通過"
      puts "   - save! 調用次數: #{retry_count}"
    end

    it '達到最大重試次數後應該拋出異常' do
      # 模擬持續衝突
      allow_any_instance_of(Account).to receive(:save!).and_raise(
        ActiveRecord::StaleObjectError.new(account, "update")
      )

      # 應該拋出 StaleObjectError
      expect {
        account.debit!(
          100,
          transaction_type: :adjustment,
          description: "測試最大重試"
        )
      }.to raise_error(ActiveRecord::StaleObjectError)

      puts "✅ 最大重試限制測試通過"
    end
  end

  describe '與 TradingService 集成' do
    it 'TradingService 的 lock! 和 Account 的樂觀鎖應該協同工作' do
      # 創建一些測試數據
      user2 = create(:user)
      user2.account.update!(balance: 20000)

      threads = []

      # 線程 1: 用戶 1 買入 (使用 TradingService)
      threads << Thread.new do
        service = TradingService.new(user)
        service.execute_order(
          symbol: 'TEST',
          side: :buy,
          quantity: 10,
          price: 100
        )
      end

      # 線程 2: 用戶 2 買入 (使用 TradingService)
      threads << Thread.new do
        service = TradingService.new(user2)
        service.execute_order(
          symbol: 'TEST',
          side: :buy,
          quantity: 10,
          price: 100
        )
      end

      # 線程 3: 用戶 1 直接扣款 (繞過 TradingService)
      threads << Thread.new do
        sleep(0.05)  # 稍微延遲
        acc = Account.find(account.id)
        acc.debit!(
          500,
          transaction_type: :adjustment,
          description: "直接扣款"
        )
      end

      threads.each(&:join)

      # 驗證兩個用戶的操作都成功
      account.reload
      user2.account.reload

      # 用戶 1: 10000 - (100*10 + 手續費) - 500
      expect(account.balance).to be < 10000
      expect(account.balance).to be > 8000

      # 用戶 2: 20000 - (100*10 + 手續費)
      expect(user2.account.balance).to be < 20000
      expect(user2.account.balance).to be > 18000

      puts "✅ TradingService 集成測試通過"
      puts "   - 用戶 1 餘額: #{account.balance}"
      puts "   - 用戶 2 餘額: #{user2.account.balance}"
    end
  end
end
