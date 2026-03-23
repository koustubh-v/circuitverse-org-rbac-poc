class ApplicationController < ActionController::API
  before_action :set_current_user

  private

  # Simulates authentication for PoC purposes.
  # Pass `X-User-Id` header to identify the acting user.
  def set_current_user
    user_id = request.headers["X-User-Id"]

    unless user_id.present?
      return render_error("Missing X-User-Id header", :unauthorized)
    end

    @current_user = User.find_by(id: user_id)

    unless @current_user
      render_error("No user found with id #{user_id}", :unauthorized)
    end
  end

  def render_success(data, status: :ok)
    render json: { success: true, data: data }, status: status
  end

  def render_error(message, status, details: nil)
    body = { success: false, error: message }
    body[:details] = details if details.present?
    render json: body, status: status
  end
end
