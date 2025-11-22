class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :account, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :transactions

  after_create :create_account!

  private

  def create_account!
    Account.create!(user: self, balance: 100_000, currency: "TWD")
  end
end
