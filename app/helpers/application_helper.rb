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
end
