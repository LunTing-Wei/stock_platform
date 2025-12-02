class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  # 定義允許的操作類型
  ACTIONS = %w[
    deposit
    withdraw
    create_order
    execute_order
  ].freeze

  validates :action, inclusion: { in: ACTIONS }

  # 按時間降序排列
  default_scope -> { order(created_at: :desc) }

  # Helper method: 記錄審計日誌
  def self.log(user:, action:, auditable: nil, metadata: {}, ip_address: nil)
    create!(
      user: user,
      action: action,
      auditable: auditable,
      metadata: metadata,
      ip_address: ip_address
    )
  end
end
