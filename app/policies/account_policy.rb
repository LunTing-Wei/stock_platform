# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  # 用戶只能查看自己的帳戶
  def show?
    user_owns_account?
  end

  # 用戶可以更新自己的帳戶（例如入金/出金）
  def update?
    user_owns_account?
  end

  # 用戶不能創建帳戶（系統自動創建）
  def create?
    false
  end

  # 用戶不能刪除帳戶
  def destroy?
    false
  end

  # Scope: 只返回用戶自己的帳戶
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def user_owns_account?
    record.user_id == user.id
  end
end
