class Api::AccountsController < Api::BaseController
  def show
    account = current_user.account

    total_position_value = current_user.positions.sum do |position|
      position.quantity * position.average_cost
    end

    render_success({
      account: {
        id: account.id,
        balance: account.balance.to_f,
        locked_balance: account.locked_balance.to_f,
        available_balance: account.available_balance.to_f,
        currency: account.currency,
        total_position_value: total_position_value.to_f,
        total_assets: (account.balance + total_position_value).to_f,
        created_at: account.created_at,
        updated_at: account.updated_at
      }
    })
  end
end
