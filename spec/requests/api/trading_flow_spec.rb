require 'rails_helper'
RSpec.describe "API::TradingFlow", type: :request do
  describe '完整交易流程集成測試' do
    let(:user) { create(:user, :with_balance, balance: 100000) }
    before do
      sign_in user, scope: :user
    end

    it '應該完成：查詢帳戶 → 買入 → 查詢持倉 → 賣出 → 查詢交易記錄' do
        # ============ 1. 查詢初始帳戶狀態 ============
        get '/api/account'
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['account']['balance']).to eq(100000.0)
        expect(json['data']['account']['total_position_value']).to eq(0.0)

        initial_balance = json['data']['account']['balance']

        # ============ 2. 買入 AAPL 10 股 @ 150 ============
        post '/api/orders', params: {
          order: {
            symbol: 'AAPL',
            side: 'buy',
            quantity: 10,
            price: 150
          }
        }
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['order']['symbol']).to eq('AAPL')
        expect(json['data']['order']['status']).to eq('completed')

        aapl_order_id = json['data']['order']['id']

        # ============ 3. 查詢持倉 - 應該有 AAPL ============
        get '/api/positions'
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['data']['positions'].size).to eq(1)

        aapl_position = json['data']['positions'].first
        expect(aapl_position['symbol']).to eq('AAPL')
        expect(aapl_position['quantity']).to eq(10.0)
        expect(aapl_position['average_cost']).to eq(150.0)

        # ============ 4. 買入 TSLA 5 股 @ 200 ============
        post '/api/orders', params: {
          order: {
            symbol: 'TSLA',
            side: 'buy',
            quantity: 5,
            price: 200
          }
        }

        expect(response).to have_http_status(:created)

        # ============ 5. 查詢持倉 - 應該有 AAPL + TSLA ============
        get '/api/positions'
        json = JSON.parse(response.body)
        expect(json['data']['positions'].size).to eq(2)
        expect(json['data']['summary']['total_positions']).to eq(2)

        # ============ 6. 賣出 AAPL 5 股 @ 160 ============
        post '/api/orders', params: {
          order: {
            symbol: 'AAPL',
            side: 'sell',
            quantity: 5,
            price: 160
          }
        }

        expect(response).to have_http_status(:created)

        # ============ 7. 查詢持倉 - AAPL 應該剩 5 股 ============
        get '/api/positions'
        json = JSON.parse(response.body)

        aapl_position = json['data']['positions'].find { |p| p['symbol'] == 'AAPL' }
        expect(aapl_position['quantity']).to eq(5.0)
        expect(aapl_position['average_cost']).to eq(150.0) # 平均成本不變

        # ============ 8. 查詢交易記錄 ============
        get '/api/transactions'
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        transactions = json['data']['transactions']

        # 應該有: 買 AAPL(2筆), 買 TSLA(2筆), 賣 AAPL(3筆) = 7筆
        expect(transactions.size).to eq(7)

        # ============ 9. 查詢訂單列表 ============
        get '/api/orders'
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        orders = json['data']['orders']
        expect(orders.size).to eq(3)
        expect(orders.all? { |o| o['status'] == 'completed' }).to be true

        # ============ 10. 查詢特定訂單詳情 ============
        get "/api/orders/#{aapl_order_id}"
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['data']['order']['id']).to eq(aapl_order_id)
        expect(json['data']['order']['symbol']).to eq('AAPL')

        # ============ 11. 驗證最終帳戶餘額 ============
        get '/api/account'
        json = JSON.parse(response.body)

        final_balance = json['data']['account']['balance']

        # 計算預期餘額
        # 初始: 100000
        # 買 AAPL: -1500 - 手續費(約2.14)
        # 買 TSLA: -1000 - 手續費(約1.43)
        # 賣 AAPL: +800 - 手續費(約1.14) - 交易稅(2.4)
        # 預期餘額約: 98292

        expect(final_balance).to be < initial_balance # 淨支出
        expect(final_balance).to be > 98000 # 大約範圍
        expect(final_balance).to be < 98500
    end

    it '應該處理錯誤情況：餘額不足' do
        # 嘗試買入超過餘額的股票
        post '/api/orders', params: {
          order: {
            symbol: 'AAPL',
            side: 'buy',
            quantity: 10000,
            price: 150
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']['code']).to eq('INSUFFICIENT_FUNDS')

        # 確認沒有建立訂單
        get '/api/orders'
        json = JSON.parse(response.body)
        expect(json['data']['orders'].size).to eq(0)
    end

    it '應該處理錯誤情況：持倉不足' do
        # 先買入
        post '/api/orders', params: {
          order: { symbol: 'AAPL', side: 'buy', quantity: 5, price: 100 }
        }

        # 嘗試賣出超過持倉的股票
        post '/api/orders', params: {
          order: { symbol: 'AAPL', side: 'sell', quantity: 10, price: 100 }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']['code']).to eq('INSUFFICIENT_POSITION')
    end

    it '應該處理訂單取消流程' do
        # 建立 pending 訂單
        service = TradingService.new(user)
        order = service.create_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 150)

        expect(order.status).to eq('pending')

        # 取消訂單
        patch "/api/orders/#{order.id}/cancel"
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['order']['status']).to eq('cancelled')

        # 確認訂單狀態
        order.reload
        expect(order.cancelled?).to be true
    end
  end
end
