FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
  end

  trait :with_balance do
    transient do
      balance { 10000 }
    end

    after(:create) do |user, evaluator|
      user.account.update!(balance: evaluator.balance)
    end
  end
end
