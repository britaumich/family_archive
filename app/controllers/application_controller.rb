class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_user

  def current_user
    Current.session&.user
  end
  
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end
end
