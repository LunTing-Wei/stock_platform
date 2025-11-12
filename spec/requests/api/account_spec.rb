require 'rails_helper'
RSpec.describe "API::Account", type: :request do
  let(:user) { create(:user, :with_balance, balance: 10000) }

  before do
    sign_in user, scope: :user

    service = TradingService.new(user)
    service.execute_order(symbol: 'AAPL', side: :buy, quantity: 10, price: 100)
    service.execute_order(symbol: 'TSLA', side: :buy, quantity: 5, price: 200)
  end

  describe "GET /api/account" do
    it '應該回傳帳戶資訊' do
      get "/api/account"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['account']).to be_present
    end

    it '應該包含餘額資訊' do
      get '/api/account'
      json = JSON.parse(response.body)

      account_data = json['data']['account']
      expect(account_data['balance']).to eq(8000.0)
      expect(account_data['locked_balance']).to eq(0.0)
      expect(account_data['available_balance']).to eq(8000.0)
      expect(account_data['currency']).to eq('USD')
    end

    it '應該包含持倉市值' do
      get '/api/account'

      json = JSON.parse(response.body)
      account_data = json['data']['account']
      expect(account_data['total_position_value']).to eq(2000.0)
    end

    it '應該包含總資產' do
      get '/api/account'

      json = JSON.parse(response.body)
      account_data = json['data']['account']
      expect(account_data['total_assets']).to eq(10000.0)
    end

    it '應該包含時間戳記' do
      get '/api/account'

      json = JSON.parse(response.body)
      account_data = json['data']['account']

      expect(account_data['created_at']).to be_present
      expect(account_data['updated_at']).to be_present
    end
  end

  describe "未登入時" do
    before do
      sign_out user
    end

    it '應該回傳 401' do
      get '/api/account'

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']['code']).to eq('UNAUTHORIZED')
    end
  end
end
