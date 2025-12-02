class Api::Sessions::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def create
    build_resource(sign_up_params)

    if resource.save
      sign_up(resource_name, resource)

      render json: {
        success: true,
        data: {
          user: {
            id: resource.id,
            email: resource.email
          }
        }
      }, status: :created
    else
      render json: {
        success: false,
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
