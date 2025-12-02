FactoryBot.define do
  factory :audit_log do
    association :user
    action { "deposit" }
    auditable_type { nil }
    auditable_id { nil }
    metadata { {} }
    ip_address { "127.0.0.1" }

    trait :with_order do
      association :auditable, factory: :order
    end

    trait :deposit do
      action { "deposit" }
      metadata { { amount: 1000, description: "入金" } }
    end

    trait :withdraw do
      action { "withdraw" }
      metadata { { amount: 500, description: "出金" } }
    end

    trait :create_order do
      action { "create_order" }
      metadata { { symbol: "AAPL", side: "buy", quantity: 10, price: 100 } }
    end
  end
end
