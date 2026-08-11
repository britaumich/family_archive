class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Authentication
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  around_action :switch_locale
  around_action :prosopite_scan, if: -> { Rails.env.development? && defined?(Prosopite) }
  helper_method :current_user

  def current_user
    Current.session&.user
  end

  def pundit_user
    { user: current_user, role: current_role }
  end
  
  def user_not_authorized
    locale = params[:locale] || I18n.default_locale
    flash[:alert] = I18n.with_locale(locale) { t('auth.not_authorized') }
    redirect_to(root_path(locale: locale))
  end

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def prosopite_scan
    Prosopite.scan
    yield
  ensure
    begin
      Prosopite.finish
    rescue LoadError => e
      Rails.logger.warn("[Prosopite] #{e.class}: #{e.message}")
    end
  end

end
