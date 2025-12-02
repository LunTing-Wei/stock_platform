class Api::AccountsController < Api::BaseController
  def show
    @account = current_user.account
    authorize @account

    total_position_value = current_user.positions.pick(
      Arel.sql("SUM(quantity * current_price)")
    ) || 0

    render_success({
      account: {
        id: @account.id,
        balance: @account.balance.to_f,
        currency: @account.currency,
        total_position_value: total_position_value.to_f,
        total_assets: (@account.balance + total_position_value).to_f,
        created_at: @account.created_at,
        updated_at: @account.updated_at
      }
    })
  end

  def deposit
    @account = current_user.account
    authorize @account, :update?
    amount  = params[:amount].to_d
    description = params[:description] || "入金"

    if amount <= 0
      return render_error("金額必須大於 0", status: :unprocessable_content)
    end

    transaction = current_user.account.credit!(
      amount,
      transaction_type: :deposit,
      description: description
    )

    AuditLog.log(
      user: current_user,
      action: "deposit",
      auditable: transaction,
      metadata: {
        amount: amount.to_f,
        description: description,
        balance_after: transaction.balance_after.to_f
      },
      ip_address: request.remote_ip
    )

    render_success({
      account: {
        balance: current_user.account.balance.to_f,
        currency: current_user.account.currency
      },
      transaction: {
        id: transaction.id,
        amount: transaction.amount.to_f,
        transaction_type: transaction.transaction_type,
        description: transaction.description,
        balance_after: transaction.balance_after.to_f,
        created_at: transaction.created_at
      }
    }, status: :created)
  end

  def withdraw
    @account = current_user.account
    authorize @account, :update?

    amount = params[:amount].to_d
    description = params[:description] || "出金"

    if amount <= 0
      return render_error("金額必須大於 0", status: :unprocessable_content)
    end

    transaction = current_user.account.debit!(
      amount,
      transaction_type: :withdrawal,
      description: description
    )

    AuditLog.log(
      user: current_user,
      action: "withdraw",
      auditable: transaction,
      metadata: {
        amount: amount.to_f,
        description: description,
        balance_after: transaction.balance_after.to_f
      },
      ip_address: request.remote_ip
    )

    render_success({
      account: {
        balance: current_user.account.balance.to_f,
        currency: current_user.account.currency
      },
      transaction: {
        id: transaction.id,
        amount: transaction.amount.to_f,
        transaction_type: transaction.transaction_type,
        description: transaction.description,
        balance_after: transaction.balance_after.to_f,
        created_at: transaction.created_at
      }
    }, status: :created)
  end
end
