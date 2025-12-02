FactoryBot.define do
  factory :daily_price do
    symbol { "MyString" }
    date { "2025-11-25" }
    open { "9.99" }
    high { "9.99" }
    low { "9.99" }
    close { "9.99" }
    volume { "" }
  end
end
