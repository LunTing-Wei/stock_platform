class Api::Sessions::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)

    render json: {
      success: true,
      data: {
        user: {
          id: resource.id,
          email: resource.email
        }
      }
    }, status: :created
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))

    if signed_out
      render json: {
        success: true,
        message: "登出成功"
      }, status: :ok
    else
      render json: {
        success: false,
        error: {
          message: "登出失敗",
          code: "SIGN_OUT_FAILED"
        }
      }, status: :unprocessable_entity
    end
  end

  private

  def respond_to_on_destroy
    head :no_content
  end
end
