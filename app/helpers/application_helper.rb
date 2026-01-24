module ApplicationHelper
  def render_flash_stream
    turbo_stream.update 'flash', partial: 'layouts/notification'
  end

  def css_class_for_flash(type)
    case type.to_sym
    when :alert
      'alert-danger'
    else
      'alert-success'
    end
  end

  def display_user_with_role(user)
    if is_admin_user?(user)
      "#{user.email_address} (Admin)"
    else
      user.email_address
    end
  end

  def is_admin_user?(user)
    return false unless user
    email = user.email_address
    cache_key = "admin_user_status:#{email}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Rails.logger.debug "********************************** Checking admin user status for #{email}"
      AdminUser.exists?(email: email)
    end
  end
end
