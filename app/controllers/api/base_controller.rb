class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  respond_to :json

  before_action :authenticate_user!

  private

  def render_success(data, status: :ok)
    render json: {
      success: true,
      data: data
    }, status: status
  end

  def render_error(message, status: :unprocessable_entity, code: nil)
    render json: {
      success: false,
      error: {
        message: message,
        code: code
      }
    }, status: status
  end

  def authenticate_user!
    unless user_signed_in?
      render_error("需要登入", status: :unauthorized, code: "UNAUTHORIZED")
      nil
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error("找不到該資源", status: :not_found, code: "NOT_FOUND")
  end

  rescue_from TradingService::InsufficientFundsError do |e|
    render_error(e.message, status: :unprocessable_entity, code: "INSUFFICIENT_FUNDS")
  end

  rescue_from TradingService::InsufficientPositionError do |e|
    render_error(e.message, status: :unprocessable_entity, code: "INSUFFICIENT_POSITION")
  end

  rescue_from ArgumentError do |e|
    render_error(e.message, status: :bad_request, code: "INVALID_PARAMS")
  end
end
