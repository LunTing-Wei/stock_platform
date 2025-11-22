class Api::Sessions::RegistrationsController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.new(sign_up_params)

    if user.save
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
        errors: user.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
