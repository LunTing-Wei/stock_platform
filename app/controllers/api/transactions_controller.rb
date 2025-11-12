class Api::TransactionsController < Api::BaseController
  def index
    transactions = current_user.account.transactions

    if params[:transaction_type].present?
      transactions = transactions.where(transaction_type: params[:transaction_type])
    end

    if params[:from].present?
      transactions = transactions.where("created_at >= ?", params[:from])
    end

    if params[:to].present?
      transactions = transactions.where("created_at <= ?", params[:to])
    end

    case params[:direction]
    when "credit"
      transactions = transactions.credits
    when "debit"
      transactions = transactions.debits
    end

    transactions = transactions.order(created_at: :desc)
    page = params[:page]&.to_i || 1
    per_page = 20
    total = transactions.count
    transactions = transactions.limit(per_page).offset((page - 1) * per_page)

    render_success({
      transactions: transactions.as_json(
        only: [ :id, :amount, :balance_after, :transaction_type, :description, :created_at ],
        include: {
          transactionable: {
            only: [ :id, :symbol, :side, :quantity, :price ]
          }
        }
      ),
      pagination: {
        current_page: page,
        per_page: per_page,
        total: total
      }
    })
  end
end
