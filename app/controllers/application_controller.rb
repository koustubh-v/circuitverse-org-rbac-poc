class ApplicationController < ActionController::API
  before_action :set_current_user

  private

  # Simulates authentication for PoC purposes.
  # Pass `X-User-Id` header to identify the acting user.
  def set_current_user
    user_id = request.headers["X-User-Id"]
    @current_user = User.find_by(id: user_id)

    render json: { error: "User not found" }, status: :unauthorized unless @current_user
  end
end
