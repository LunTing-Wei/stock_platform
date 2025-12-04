class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :account, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :transactions
  has_many :audit_logs, dependent: :destroy

  after_create :create_account!

  def admin?
    admin
  end

  # Fix for Devise 4.9.4 with Rails 8.0 compatibility issue
  # Rails 8 changed Warden's session serialization to pass 5 arguments instead of 2
  # https://github.com/heartcombo/devise/issues/5645
  def self.serialize_from_session(key, salt, *args)
    # key is the user ID, just find by ID
    find_by(id: key)
  end

  private

  def create_account!
    Account.create!(user: self, balance: 100_000, currency: "TWD")
  end
end
