require 'rails_helper'

RSpec.describe "API::Orders", type: :request do
  let(:user) { create(:user, :with_balance, balance: 10000) }

  before do
    sign_in user, scope: :user
  end

  describe "POST /api/orders" do
    context '當參數正確時' do
      let(:valid_params) do
        {
          order: {
            symbol: 'AAPL',
            side: 'buy',
            quantity: 10,
            price: 100
          }
        }
      end

      it '應該成功建立訂單' do
        post '/api/orders', params: valid_params

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']).to be_present
        expect(json['data']['order']).to be_present

        order_data = json['data']['order']
        expect(order_data['symbol']).to eq('AAPL')
        expect(order_data['side']).to eq('buy')
        expect(order_data['quantity'].to_f).to eq(10.0)
        expect(order_data['price'].to_f).to eq(100.0)
        expect(order_data['status']).to eq('completed')
      end

      it '應該扣除帳戶餘額' do
        expect {
          post '/api/orders', params: valid_params
        }.to change { user.account.reload.balance }.by(-1001)
      end

      it '應該建立訂單記錄' do
        expect {
          post '/api/orders', params: valid_params
        }.to change { user.orders.count }.by(1)
      end
    end

    context '當餘額不足時' do
      let(:invalid_params) do
        {
          order: {
            symbol: 'AAPL',
            side: 'buy',
            quantity: 200,
            price: 100
          }
        }
      end

      it '應該回傳錯誤' do
        post '/api/orders', params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to be_present
        expect(json['error']['code']).to eq('INSUFFICIENT_FUNDS')
        expect(json['error']['message']).to include('餘額不足')
      end

      it '不應該建立訂單' do
        expect {
          post '/api/orders', params: invalid_params
        }.not_to change { user.orders.count }
      end
    end

    context '當參數缺少時' do
      it '應該回傳錯誤' do
        post '/api/orders', params: { order: { symbol: 'AAPL' } }

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context '當參數無效時' do
      let(:invalid_params) do
        {
          order: {
            symbol: '',
            side: 'buy',
            quantity: 10,
            price: 100
          }
        }
      end

      it '應該回傳參數錯誤' do
        post '/api/orders', params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']['code']).to eq('INVALID_PARAMS')
      end
    end
  end

  describe "GET /api/orders" do
    before do
      service = TradingService.new(user)
      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
      service.execute_order(symbol: 'TSLA', side: :buy, quantity: 5, price: 200)
      service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)
    end

    it '應該回傳訂單列表' do
      get '/api/orders'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['orders']).to be_an(Array)
      expect(json['data']['orders'].size).to eq(3)
    end

    it '應該按時間降序排列' do
      get '/api/orders'

      json = JSON.parse(response.body)
      orders = json['data']['orders']

      # 第一筆應該是最新的（AAPL sell）
      expect(orders.first['symbol']).to eq('AAPL')
      expect(orders.first['side']).to eq('sell')
    end

    it '應該包含分頁資訊' do
      get '/api/orders'

      json = JSON.parse(response.body)
      expect(json['data']['pagination']).to be_present
      expect(json['data']['pagination']['current_page']).to eq(1)
      expect(json['data']['pagination']['per_page']).to eq(20)
      expect(json['data']['pagination']['total']).to eq(3)
    end

    context '當使用篩選條件時' do
      it '可以根據 symbol 篩選' do
        get '/api/orders', params: { symbol: 'AAPL' }

        json = JSON.parse(response.body)
        orders = json['data']['orders']

        expect(orders.size).to eq(2)
        orders.each do |order|
          expect(order['symbol']).to eq('AAPL')
        end
      end

      it '可以根據 side 篩選' do
        get '/api/orders', params: { side: 'buy' }

        json = JSON.parse(response.body)
        orders = json['data']['orders']

        expect(orders.size).to eq(2)
        orders.each do |order|
          expect(order['side']).to eq('buy')
        end
      end

      it '可以組合多個篩選條件' do
        get '/api/orders', params: { symbol: 'AAPL', side: 'buy' }

        json = JSON.parse(response.body)
        orders = json['data']['orders']

        expect(orders.size).to eq(1)
        expect(orders.first['symbol']).to eq('AAPL')
        expect(orders.first['side']).to eq('buy')
      end
    end
  end

  describe "GET /api/orders/:id" do
    let(:order) do
      service = TradingService.new(user)
      service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
    end

    it '應該回傳訂單詳情' do
      get "/api/orders/#{order.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['order']['id']).to eq(order.id)
      expect(json['data']['order']['symbol']).to eq('AAPL')
    end

    context '當訂單不存在時' do
      it '應該回傳 404 錯誤' do
        get "/api/orders/99999"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']['code']).to eq('NOT_FOUND')
      end
    end

    context '當嘗試查詢別人的訂單時' do
      it '應該回傳 404 錯誤' do
        other_user = create(:user, :with_balance, balance: 10000)
        other_service = TradingService.new(other_user)
        other_order = other_service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)

        get "/api/orders/#{other_order.id}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '未登入時' do
    before do
      sign_out user
    end

    it 'POST /api/orders 應該回傳 401' do
      post '/api/orders', params: { order: { symbol: 'AAPL', side: 'buy', quantity: 10, price: 100 } }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'GET /api/orders 應該回傳 401' do
      get '/api/orders'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
