class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Authentication
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :set_locale

  helper_method :current_user

  def current_user
    Current.session&.user
  end
  
  def user_not_authorized
    flash[:alert] = t('auth.not_authorized')
    redirect_to(root_path)
  end

  def set_locale
    if cookies[:educator_locale] && I18n.available_locales.include?(cookies[:educator_locale].to_sym)
      l = cookies[:educator_locale].to_sym
    else
      l = I18n.default_locale
      cookies.permanent[:educator_locale] = l
    end
    I18n.locale = l
  end
end
