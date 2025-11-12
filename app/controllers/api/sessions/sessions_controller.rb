class Api::Sessions::SessionsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.find_by(email: params[:user][:email])

    if user && user.valid_password?(params[:user][:password])
      reset_session
      session[:user_id] = user.id

      render json: {
        success: true,
        data: {
          user: {
            id: user.id,
            email: user.email
          }
        }
      }, status: :created
    else
      render json: {
        success: false,
        error: {
          message: "帳號或密碼錯誤",
          code: "INVALID_CREDENTIALS"
        }
      }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    response.set_cookie(
      :_stock_platform_session,
      value: "",
      expires: 1.year.ago,
      path: "/",
      httponly: true,
      same_site: :lax
    )

    render json: {
      success: true,
      message: "登出成功"
    }, status: :ok
  end
end
