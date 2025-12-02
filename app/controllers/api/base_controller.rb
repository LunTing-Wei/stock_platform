class Api::BaseController < ApplicationController
  include Pundit::Authorization
  skip_before_action :verify_authenticity_token

  respond_to :json

  before_action :authenticate_user!

  private

  def authenticate_user!
    unless current_user
      render_error("請先登入", status: :unauthorized, code: "UNAUTHORIZED")
      return
    end
  end

  def render_success(data, status: :ok)
    render json: {
      success: true,
      data: data
    }, status: status
  end

  def render_error(message, status: :unprocessable_content, code: nil)
    render json: {
      success: false,
      error: {
        message: message,
        code: code
      }
    }, status: status
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error("找不到該資源", status: :not_found, code: "NOT_FOUND")
  end

  rescue_from TradingService::InsufficientFundsError do |e|
    render_error(e.message, status: :unprocessable_content, code: "INSUFFICIENT_FUNDS")
  end

  rescue_from TradingService::InsufficientPositionError do |e|
    render_error(e.message, status: :unprocessable_content, code: "INSUFFICIENT_POSITION")
  end

  rescue_from Account::InsufficientFundsError do |e|
    render_error(e.message, status: :unprocessable_content, code: "INSUFFICIENT_FUNDS")
  end

  rescue_from ArgumentError do |e|
    render_error(e.message, status: :unprocessable_content, code: "INVALID_PARAMS")
  end

  rescue_from Pundit::NotAuthorizedError do |e|
    render_error("您沒有權限執行此操作", status: :forbidden, code: "FORBIDDEN")
  end
end
