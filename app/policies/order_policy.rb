# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  # 用戶可以查看自己的所有訂單
  def index?
    true
  end

  # 用戶只能查看自己的訂單
  def show?
    user_owns_order?
  end

  # 用戶可以創建訂單
  def create?
    true
  end

  # 用戶不能更新訂單（訂單一旦創建就不可修改）
  def update?
    false
  end

  # 用戶不能刪除訂單（訂單記錄需要保留）
  def destroy?
    false
  end

  # Scope: 只返回用戶自己的訂單
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def user_owns_order?
    record.user_id == user.id
  end
end
