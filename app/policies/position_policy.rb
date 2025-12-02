# frozen_string_literal: true

class PositionPolicy < ApplicationPolicy
  # 用戶可以查看自己的所有持倉
  def index?
    true
  end

  # 用戶只能查看自己的持倉
  def show?
    user_owns_position?
  end

  # 用戶不能直接創建持倉（通過交易自動創建）
  def create?
    false
  end

  # 用戶不能直接更新持倉（通過交易自動更新）
  def update?
    false
  end

  # 用戶不能直接刪除持倉（通過交易自動刪除）
  def destroy?
    false
  end

  # Scope: 只返回用戶自己的持倉
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def user_owns_position?
    record.user_id == user.id
  end
end
