require 'rails_helper'
RSpec.describe "API::Transactions", type: :request do
  let(:user) { create(:user, :with_balance, balance: 10000) }

  before do
    sign_in user, scope: :user

    service = TradingService.new(user)
    service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
    service.execute_order(symbol: 'TSLA', side: :buy, quantity: 5, price: 200)
    service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)
  end

  describe "GET /api/transactions" do
    it '應該回傳交易記錄列表' do
      get '/api/transactions'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['transactions']).to be_an(Array)
      expect(json['data']['transactions'].size).to eq(3)
      end

    it '應該按時間降序排列' do
      get '/api/transactions'

      json = JSON.parse(response.body)
      transactions = json['data']['transactions']

      expect(transactions.first['transaction_type']).to eq('sell')
      expect(transactions.first['amount'].to_f).to be > 0  # 賣出是正數
    end

    it '應該包含交易詳細資訊' do
      get '/api/transactions'

      json = JSON.parse(response.body)
      transaction = json['data']['transactions'].first

      expect(transaction['id']).to be_present
      expect(transaction['amount']).to be_present
      expect(transaction['balance_after']).to be_present
      expect(transaction['transaction_type']).to be_present
      expect(transaction['description']).to be_present
      expect(transaction['created_at']).to be_present
    end

    it '應該包含關聯的訂單資訊' do
      get '/api/transactions'

      json = JSON.parse(response.body)
      transaction = json['data']['transactions'].first

      expect(transaction['transactionable']).to be_present
      expect(transaction['transactionable']['symbol']).to be_present
      expect(transaction['transactionable']['side']).to be_present
    end

    it '應該包含分頁資訊' do
      get '/api/transactions'

      json = JSON.parse(response.body)
      expect(json['data']['pagination']).to be_present
      expect(json['data']['pagination']['current_page']).to eq(1)
      expect(json['data']['pagination']['per_page']).to eq(20)
      expect(json['data']['pagination']['total']).to eq(3)
    end

    context '當使用篩選條件時' do
      it '可以根據 transaction_type 篩選' do
        get '/api/transactions', params: { transaction_type: 'buy' }

        json = JSON.parse(response.body)
        transactions = json['data']['transactions']

        expect(transactions.size).to eq(2)
        transactions.each do |tx|
          expect(tx['transaction_type']).to eq('buy')
        end
      end

      it '可以根據 direction 篩選入帳記錄' do
        get '/api/transactions', params: { direction: 'credit' }

        json = JSON.parse(response.body)
        transactions = json['data']['transactions']

        expect(transactions.size).to eq(1)
        transactions.each do |tx|
          expect(tx['amount'].to_f).to be > 0
        end
      end

      it '可以根據 direction 篩選出帳記錄' do
        get '/api/transactions', params: { direction: 'debit' }

        json = JSON.parse(response.body)
        transactions = json['data']['transactions']

        expect(transactions.size).to eq(2)
        transactions.each do |tx|
          expect(tx['amount'].to_f).to be < 0
        end
      end

      it '可以根據日期範圍篩選' do
        service = TradingService.new(user)
        service.execute_order(symbol: 'GOOGL', side: :buy, quantity: 2, price: 100)

        get '/api/transactions'
        json = JSON.parse(response.body)
        expect(json['data']['transactions'].size).to eq(4)

        get '/api/transactions', params: { from: '2000-01-01T00:00:00Z' }
        json = JSON.parse(response.body)
        expect(json['data']['transactions'].size).to eq(4)


        get '/api/transactions', params: { from: '2099-01-01T00:00:00Z' }
        json = JSON.parse(response.body)
        expect(json['data']['transactions'].size).to eq(0)
      end
    end
  end

  describe '未登入時' do
    before do
      sign_out user
    end

    it '應該回傳 401' do
      get '/api/transactions'

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']['code']).to eq('UNAUTHORIZED')
    end
  end
end
