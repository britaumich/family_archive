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
      current_user.email_address
    end
  end

  def is_admin_user?(user)
    user && AdminUser.exists?(email: user.email_address)
  end
end
