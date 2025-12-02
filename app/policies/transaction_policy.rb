# frozen_string_literal: true

class TransactionPolicy < ApplicationPolicy
  # 用戶可以查看自己的所有交易記錄
  def index?
    true
  end

  # 用戶只能查看自己的交易記錄
  def show?
    user_owns_transaction?
  end

  # 用戶不能直接創建交易記錄（通過系統自動創建）
  def create?
    false
  end

  # 用戶不能更新交易記錄（交易記錄不可變）
  def update?
    false
  end

  # 用戶不能刪除交易記錄（交易記錄不可刪除）
  def destroy?
    false
  end

  # Scope: 只返回用戶自己的交易記錄
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def user_owns_transaction?
    record.user_id == user.id
  end
end
