# Stock Trading Platform - 開發計劃

## 📚 專案性質

### 核心目標

這是一個**練習專案**,主要目的是:

- ✅ **學習 Ruby on Rails** 的語法、慣例和最佳實踐
- ✅ **學習 React** 的語法、慣例和狀態管理
- ✅ **理解全端開發**的完整流程
- ✅ **掌握生產環境**的開發標準

### 開發原則

1. ⭐ **以生產環境為目標**:代碼品質、安全性、可維護性優先
2. ⭐ **不追求快速上線**:寧可慢慢做對,不要留技術債
3. ⭐ **完整性 > 速度**:完整的解決方案比快速但有缺陷的方案更重要
4. ⭐ **相容性優先**:確保代碼在不同環境下都能正常運作
5. ⭐ **學習導向**:每個決策都需要理解「為什麼」和「怎麼做」

### 開發方式

- **AI (Claude)** 提供:

  - 功能開發的詳細說明
  - 語法解釋和範例
  - 為什麼這麼寫的原因
  - Rails/React 慣例和架構解釋
  - 最佳實踐建議

- **開發者(你)** 負責:
  - 實際撰寫程式碼
  - 提問和理解概念
  - 做出技術決策

---

## 🛠️ 技術棧

### 後端

- **Ruby**: 3.3.9
- **Rails**: 8.0.3
- **資料庫**: PostgreSQL
- **認證**: Devise 4.9.4
- **權限**: Pundit 2.4.0
- **背景任務**: Sidekiq(計劃中)
- **測試**: RSpec
- **速率限制**: Rack::Attack

### 前端

- **React**: 18.x
- **狀態管理**: Context API(計劃升級到 React Query)
- **HTTP 客戶端**: Axios
- **路由**: React Router

### 基礎設施

- **錯誤監控**: Sentry(已配置)
- **部署**: (待定)
- **CI/CD**: (待定)

---

## ✅ 已完成功能

### P0 系列:核心穩定性(已完成)

- ✅ **P0.1** - 修復 TradingService 並發控制 bug

  - 使用 `ActiveRecord::Base.transaction` 確保原子性
  - 使用 `lock!` 防止並發衝突

- ✅ **P0.2** - 修復 Account#debit! 的樂觀鎖問題

  - 實現 `lock_version` 樂觀鎖
  - 自動重試機制(最多 3 次)

- ✅ **P0.3** - 驗證並發測試通過

  - 141 個測試全部通過
  - 包含並發場景測試

- ✅ **P0.4** - 實現基於 Pundit 的權限系統

  - ApplicationPolicy 基類
  - OrderPolicy, AccountPolicy 等

- ✅ **P0.5** - 為所有 Controller 添加權限檢查

  - 所有敏感操作都有 `authorize` 檢查
  - 自動驗證未授權錯誤

- ✅ **P0.6** - 實現完整的審計日誌系統
  - AuditLog model
  - 記錄所有重要操作(create_order, cancel_order, deposit, withdraw)
  - 多型關聯(polymorphic association)

### P1 系列:高度推薦(已完成)

- ✅ **P1.1** - 修復手續費測試 + Rack::Attack 測試干擾

  - 在測試環境禁用 Rack::Attack

- ✅ **P1.2** - 修復浮點數精度問題

  - 使用 `BigDecimal` 處理價格和金額

- ✅ **P1.3** - 實現 Order 狀態機

  - 狀態:pending → completed / cancelled
  - 狀態轉換方法:`execute!`, `cancel!`
  - 數據遷移確保數據一致性

- ✅ **P1.4** - 為 /api/orders 添加速率限制

  - 10 次/分鐘

- ✅ **P1.5** - 補充 API 輸入驗證

  - Symbol 格式驗證(1-10 大寫字母)
  - 數量、價格正數驗證
  - Side 枚舉驗證

- ✅ **P1.6** - 為 StockPricesController#import 添加管理員權限

  - 只有管理員可以導入股價

- ✅ **P1.8** - 補充 API 集成測試
  - 完整交易流程測試
  - 錯誤處理測試
  - 訂單取消流程測試

### P2 系列:部分完成

- ✅ **P2.3** - 移除 Position#as_json, 改在 Controller 序列化
  - 遵循 Rails 最佳實踐
  - Controller 負責序列化邏輯

### 關鍵 Bug 修復

- ✅ **Devise 4.9.4 + Rails 8.0 兼容性問題**

  - 覆寫 `User.serialize_from_session` 方法
  - 接受可變參數 `*args`

- ✅ **TradingService 尾隨逗號語法錯誤**

  - 移除 `status: :pending,` 後的逗號

- ✅ **OrderPolicy 缺少 cancel? 方法**

  - 添加權限檢查

- ✅ **AuditLog ACTIONS 白名單缺少 cancel_order**
  - 添加到允許列表

---

## 🎯 待處理任務

### ✅ 已完成 Must Fix

---

#### ~~P2.1 - 修復前端 AuthContext 認證邏輯~~ ✅

**已完成修復:**
- ✅ 添加 Axios interceptor 捕捉 401 錯誤
- ✅ AuthContext 監聽 auth:logout 事件
- ✅ 改進 checkAuth 只在 401 時登出
- ✅ 改進 logout 的 try-catch-finally
- ✅ 所有測試通過

**修改文件:**
- `frontend/src/api/client.js` - 添加 response interceptor
- `frontend/src/context/AuthContext.jsx` - 監聽登出事件

---

#### ~~P2.6 - 修復分頁邊界檢查~~ ✅

**已完成修復:**
- ✅ page 參數限制 >= 1
- ✅ per_page 參數限制在 1-100 之間
- ✅ 防止負數和過大值導致的 DoS
- ✅ Rails Console 測試通過

**修改文件:**
- `app/controllers/api/orders_controller.rb:14-17`

**修改代碼:**
```ruby
page = params[:page]&.to_i || 1
page = [page, 1].max
per_page = params[:per_page]&.to_i || 20
per_page = [[per_page, 100].min, 1].max
```

---

### ⏸️ Can Wait (等有真實問題再說)

這些「可能」有用,但現在做是浪費時間。

---

#### P2.4 - StockPriceUpdateService 重試機制

**為什麼可以等:**

- 外部 API 現在有失敗過嗎?
- 失敗時有日誌記錄嗎?
- 如果都沒有,你怎麼知道需要重試?

**什麼時候做:**
等你真的遇到 API 不穩定,再來實現重試。

**如果要做,用這個:**

```ruby
class StockPriceUpdateJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(symbol)
    service = StockPriceImportService.new(symbol)
    result = service.import_recent_data(30)
    raise StandardError, result[:message] unless result[:success]
  end
end
```

---

#### P2.9 - 性能基準測試

**為什麼可以等:**

- 你現在有幾個用戶? 0 個
- 有性能問題嗎? 不知道
- 那測試個屁?

**什麼時候做:**

1. 等有 10+ 個真實用戶
2. 用戶抱怨「好慢」
3. 那時候再測試,找瓶頸

**如果要做,測這些:**

```bash
# 1. API 響應時間
ab -n 1000 -c 10 http://localhost:3000/api/orders

# 2. N+1 查詢檢測
gem 'bullet', group: :development

# 3. 並發交易壓測
# 寫個 RSpec 測 10 個用戶同時下單
```

---

#### P2.5 - Position 清空日誌

**為什麼可以等:**

- Position 清空時沒記錄到 AuditLog = 輕微的審計缺失
- 但不會造成資料錯誤或安全問題

**什麼時候做:**
等你需要查 Position 歷史記錄時,發現找不到清空記錄,那時再加。

**如果要做:**

```ruby
# 在 TradingService#execute_sell_transaction 中添加
if position.quantity.zero?
  AuditLog.log(
    user: @user,
    action: "clear_position",
    auditable: position,
    metadata: { symbol: position.symbol, final_quantity: 0 }
  )
  position.destroy!
end

# 別忘了添加到 ACTIONS 白名單
ACTIONS = %w[deposit withdraw create_order execute_order cancel_order clear_position].freeze
```

---

#### P3.2 - 對帳單/報表系統

**為什麼可以等:**

- 沒有用戶,要對什麼帳?
- 等有人用了,說「我想看報表」,再做

**如果要做,先做 CSV 就好:**

```ruby
def transactions_csv
  transactions = current_user.transactions
    .where(created_at: params[:from]..params[:to])

  send_data CSV.generate { |csv|
    csv << ['日期', '類型', '金額', '餘額']
    transactions.each { |t| csv << [...] }
  }, filename: "transactions.csv"
end
```

---

#### P2.2 - React Query 重構

**為什麼可以等:**

- 現有的 Context API 有什麼問題?
- 如果沒問題,幹嘛重構?

**什麼時候做:**
等你遇到這些問題時:

- 快取管理變複雜
- 重複的 loading/error 處理太多
- 資料同步問題

---

### ❌ Don't Do (別浪費時間)

---

#### ~~P5.1 - 專案改名~~

**為什麼不做:**

- 命名不一致有造成 bug 嗎? → 沒有
- 有用戶抱怨嗎? → 沒有用戶
- 測試有失敗嗎? → 141 個全過

**結論:**
Code 能跑就行,命名不一致是美學問題,不是技術問題。

---

#### ~~P1.7 - OpenAPI/Swagger 文檔~~

**為什麼不做:**
單人練習專案,寫 API 文檔給誰看?

---

#### ~~P1.9 - 測試覆蓋率 90%+~~

**為什麼不做:**
141 個測試已經覆蓋核心功能,追求覆蓋率數字是虛榮指標。

---

#### ~~P2.7 - 快取優化~~

#### ~~P2.8 - API 版本管理~~

#### ~~P3.1 - 價格提醒系統~~

#### ~~P4.1 - 股息配發系統~~

#### ~~P4.2 - 投資組合分析~~

**為什麼不做:**
過早優化。等有真實需求再說。

---

## 📊 當前專案狀態

### 測試覆蓋

```bash
$ bundle exec rspec

141 examples, 0 failures, 3 pending
```

### 核心功能完整度

- ✅ 用戶認證(Devise)
- ✅ 權限控制(Pundit)
- ✅ 交易系統(買入/賣出)
- ✅ 帳戶管理(餘額/持倉)
- ✅ 審計日誌(AuditLog)
- ✅ 並發控制(樂觀鎖)
- ✅ 速率限制(Rack::Attack)
- ✅ API 驗證(完整)
- ⏸️ 對帳單(等用戶需求)
- ⏸️ 性能測試(等真實流量)

---

## 🎯 上線檢查清單

### 安全性 ✅

- [x] 認證系統正常運作
- [x] 權限檢查完整
- [x] API 輸入驗證
- [x] SQL Injection 防護
- [x] CSRF 保護
- [x] 速率限制

### 穩定性 ✅

- [x] 並發控制
- [x] 樂觀鎖
- [x] 交易原子性
- [x] 錯誤處理
- [x] 前端認證邏輯(P2.1 已完成)
- [x] 分頁邊界檢查(P2.6 已完成)

### 可維護性 ✅

- [x] 代碼規範
- [x] 測試覆蓋
- [x] 審計日誌

---

## 📝 開發紀錄

### 2025-12-04

- ✅ 重新整理開發計劃優先級
- ✅ 完成 P2.1 - 修復前端認證邏輯
  - 添加 Axios interceptor 捕捉 401 錯誤
  - AuthContext 監聽 auth:logout 事件自動登出
  - 改進 checkAuth 和 logout 邏輯
- ✅ 完成 P2.6 - 修復分頁邊界檢查
  - page 參數限制 >= 1
  - per_page 參數限制在 1-100 之間
  - 防止 DoS 攻擊
- ✅ 所有 Must Fix 任務完成,系統已可上線

### 2025-12-03

- ✅ 完成 P1.8 - API 集成測試
- ✅ 修復 Devise 4.9.4 + Rails 8.0 兼容性問題
- ✅ 修復 TradingService 尾隨逗號問題
- ✅ 添加 OrderPolicy#cancel? 方法
- ✅ 添加 AuditLog ACTIONS: cancel_order
- ✅ 所有測試通過(141 examples, 0 failures)

---

## 🔄 下次開始時

### 快速恢復上下文

1. 運行測試確認狀態:`bundle exec rspec`
2. 從 P2.1 前端認證檢查開始
3. 然後修復 P2.6 分頁邊界
4. 這兩個修完就可以考慮部署了

### 當前優先級

1. 🔥 **P2.1** - 前端認證修復(安全問題)
2. 🔥 **P2.6** - 分頁邊界檢查(DoS 防護)
3. ✅ 部署上線
4. ⏸️ 等用戶反饋再決定下一步

---

## 📚 重要參考資料

### Rails 慣例

- [Rails Guides](https://guides.rubyonrails.org/)
- [RSpec Best Practices](https://rspec.info/documentation/)
- [Pundit Documentation](https://github.com/varvet/pundit)

### React 學習

- [React Docs](https://react.dev/)
- [React Query](https://tanstack.com/query/latest)

### 專案相關

- `README.md` - 專案說明
- `CLAUDE.md` - AI 助手指引
- `.env.example` - 環境變數範例

---

## 💬 開發問題記錄

### Q: 為什麼用 Pundit 而不是 CanCanCan?

**A**: Pundit 符合單一職責原則,每個 Model 有獨立的 Policy,易於測試和維護。

### Q: 為什麼用 BigDecimal 而不是 Float?

**A**: 金融交易需要精確計算,Float 有浮點數誤差問題。

### Q: 為什麼要 AuditLog?

**A**: 金融平台需要完整的審計追蹤,符合法規要求,也方便調查問題。

### Q: 什麼時候應該用 Policy,什麼時候用 before_action?

**A**: 權限檢查用 Policy,其他邏輯用 before_action。Policy 可複用、易測試。

### Q: 為什麼不先做專案改名?

**A**: 因為命名不一致不會導致 bug。Code 能跑就是好 code,美觀是次要的。

---

_最後更新:2025-12-04_
_當前狀態:準備修復 P2.1 和 P2.6,然後上線_
