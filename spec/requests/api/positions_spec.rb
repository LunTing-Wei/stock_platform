require 'rails_helper'
RSpec.describe "API::Positions", type: :request do
  let(:user) { create(:user, :with_balance, balance: 10000) }

  before do
    sign_in user, scope: :user

    service = TradingService.new(user)
    service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
    service.execute_order(symbol: 'TSLA', side: :buy, quantity: 5, price: 200)
  end

  describe "GET /api/positions" do
    it '應該回傳持倉列表' do
      get '/api/positions'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['positions']).to be_an(Array)
      expect(json['data']['positions'].size).to eq(2)
    end

    it '應該包含持倉詳細資訊' do
      get '/api/positions'

      json = JSON.parse(response.body)
      position = json['data']['positions'].first

      expect(position['id']).to be_present
      expect(position['symbol']).to be_present
      expect(position['quantity']).to be_present
      expect(position['average_cost']).to be_present
      expect(position['current_price']).to be_present
      expect(position['market_value']).to be_present
      expect(position['cost_basis']).to be_present
      expect(position['profit_loss']).to be_present
      expect(position['profit_loss_percentage']).to be_present
    end

    it '應該正確計算持倉市值' do
      get '/api/positions'

      json = JSON.parse(response.body)
      positions = json['data']['positions']
      aapl = positions.find { |p| p['symbol'] == 'AAPL' }
      expect(aapl['quantity']).to eq(10.0)
      expect(aapl['average_cost']).to eq(100.0)
      expect(aapl['market_value']).to eq(1000.0)
      expect(aapl['cost_basis']).to eq(1000.0)
    end

    it '應該按股票代碼排序' do
      get '/api/positions'

      json = JSON.parse(response.body)
      positions = json['data']['positions']
      symbols = positions.map { |p| p['symbol'] }

      expect(symbols).to eq([ 'AAPL', 'TSLA' ])
    end

    it '應該包含彙總資訊' do
      get '/api/positions'

      json = JSON.parse(response.body)
      summary = json['data']['summary']

      expect(summary['total_positions']).to eq(2)
      expect(summary['total_market_value']).to eq(2000.0)  # 1000 + 1000
      expect(summary['total_cost_basis']).to eq(2000.0)
      expect(summary['total_profit_loss']).to eq(0.0)
      expect(summary['total_profit_loss_percentage']).to eq(0.0)
    end

    context '當使用篩選條件時' do
      it '可以根據 symbol 篩選' do
        get '/api/positions', params: { symbol: 'AAPL' }

        json = JSON.parse(response.body)
        positions = json['data']['positions']

        expect(positions.size).to eq(1)
        expect(positions.first['symbol']).to eq('AAPL')
      end
    end

    context '當賣出部分持倉後' do
      before do
        service = TradingService.new(user)
        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 5, price: 150)
      end

      it '應該更新持倉數量' do
        get '/api/positions'

        json = JSON.parse(response.body)
        aapl = json['data']['positions'].find { |p| p['symbol'] == 'AAPL' }

        expect(aapl['quantity']).to eq(5.0)
      end

      it '平均成本不應該改變' do
        get '/api/positions'

        json = JSON.parse(response.body)
        aapl = json['data']['positions'].find { |p| p['symbol'] == 'AAPL' }

        expect(aapl['average_cost']).to eq(100.0)  # 保持不變
      end
    end

    context '當全部賣出後' do
      before do
        service = TradingService.new(user)
        service.execute_order(symbol: 'AAPL', side: :sell, quantity: 10, price: 150)
      end

      it '應該不顯示該持倉' do
        get '/api/positions'

        json = JSON.parse(response.body)
        positions = json['data']['positions']

        expect(positions.size).to eq(1)  # 只剩 TSLA
        expect(positions.first['symbol']).to eq('TSLA')
      end
    end
  end

  describe "GET /api/positions/:id" do
    let(:position) { user.positions.find_by(symbol: 'AAPL') }

    it '應該回傳持倉詳情' do
      get "/api/positions/#{position.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['position']['id']).to eq(position.id)
      expect(json['data']['position']['symbol']).to eq('AAPL')
    end

    context '當持倉不存在時' do
      it '應該回傳 404 錯誤' do
        get "/api/positions/99999"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']['code']).to eq('NOT_FOUND')
      end
    end

    context '當嘗試查詢別人的持倉時' do
      it '應該回傳 404 錯誤' do
        other_user = create(:user, :with_balance, balance: 10000)
        other_service = TradingService.new(other_user)
        other_service.execute_order(symbol: 'GOOGL', side: :buy, quantity: 10, price: 100)
        other_position = other_user.positions.first

        get "/api/positions/#{other_position.id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '未登入時' do
    before do
      sign_out user
    end

    it 'GET /api/positions 應該回傳 401' do
      get '/api/positions'

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']['code']).to eq('UNAUTHORIZED')
    end

    it 'GET /api/positions/:id 應該回傳 401' do
      get '/api/positions/1'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
