require 'rails_helper'
RSpec.describe "API::Account", type: :request do
  describe "未登入時" do
    before do
      # 確保沒有登入狀態
      Warden.test_reset!
    end

    it '應該回傳 401' do
      get '/api/account'

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']['code']).to eq('UNAUTHORIZED')
    end
  end


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
      expect(account_data['balance']).to eq(7998.0)
      expect(account_data['currency']).to eq('TWD')
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
      expect(account_data['total_assets']).to eq(9998.0)
    end

    it '應該包含時間戳記' do
      get '/api/account'

      json = JSON.parse(response.body)
      account_data = json['data']['account']

      expect(account_data['created_at']).to be_present
      expect(account_data['updated_at']).to be_present
    end
  end
  describe "POST /api/account/deposit" do
    it '應該能成功入金' do
      initial_balance = user.account.balance

      post '/api/account/deposit', params: { amount: 1000 }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['account']['balance']).to eq((initial_balance + 1000).to_f)
      expect(json['data']['transaction']['amount']).to eq(1000.0)
      expect(json['data']['transaction']['transaction_type']).to eq('deposit')
    end

    it '應該能指定入金描述' do
      post '/api/account/deposit', params: { amount: 500, description: '銀行轉帳' }

      json = JSON.parse(response.body)
      expect(json['data']['transaction']['description']).to eq('銀行轉帳')
    end

    it '金額為 0 時應該回傳錯誤' do
      post '/api/account/deposit', params: { amount: 0 }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json['success']).to be false
      expect(json['error']['message']).to eq('金額必須大於 0')
    end

    it '金額為負數時應該回傳錯誤' do
      post '/api/account/deposit', params: { amount: -100 }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json['success']).to be false
    end

    it '應該建立 Transaction 記錄' do
      expect {
        post '/api/account/deposit', params: { amount: 1000 }
      }.to change(Transaction, :count).by(1)

      transaction = Transaction.last
      expect(transaction.transaction_type).to eq('deposit')
      expect(transaction.amount).to eq(1000.0)
    end
  end

  describe "POST /api/account/withdraw" do
    it '應該能成功出金' do
      initial_balance = user.account.balance

      post '/api/account/withdraw', params: { amount: 1000 }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['account']['balance']).to eq((initial_balance - 1000).to_f)
      expect(json['data']['transaction']['amount']).to eq(-1000.0)  # 負數表示扣款
      expect(json['data']['transaction']['transaction_type']).to eq('withdrawal')
    end

    it '應該能指定出金描述' do
      post '/api/account/withdraw', params: { amount: 500, description: '提款到銀行' }

      json = JSON.parse(response.body)
      expect(json['data']['transaction']['description']).to eq('提款到銀行')
    end

    it '金額為 0 時應該回傳錯誤' do
      post '/api/account/withdraw', params: { amount: 0 }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json['success']).to be false
      expect(json['error']['message']).to eq('金額必須大於 0')
    end

    it '金額為負數時應該回傳錯誤' do
      post '/api/account/withdraw', params: { amount: -100 }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it '餘額不足時應該回傳錯誤' do
      post '/api/account/withdraw', params: { amount: 999999 }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json['success']).to be false
      expect(json['error']['message']).to include('餘額不足')
    end
    it '應該建立 Transaction 記錄' do
      expect {
        post '/api/account/withdraw', params: { amount: 1000 }
      }.to change(Transaction, :count).by(1)

      transaction = Transaction.last
      expect(transaction.transaction_type).to eq('withdrawal')
      expect(transaction.amount).to eq(-1000.0)
    end
  end
end
