class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Authentication
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  around_action :switch_locale

  helper_method :current_user

  def current_user
    Current.session&.user
  end
  
  def user_not_authorized
    flash[:alert] = t('auth.not_authorized')
    redirect_to(root_path)
  end

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: I18n.locale }
  end

end
