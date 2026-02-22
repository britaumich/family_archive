# Bullet configuration for N+1 query detection
if defined?(Bullet)
  Bullet.enable        = true
  # Bullet.alert         = Rails.env.development?
  Bullet.alert = true # Disable browser alerts (can be annoying)
  Bullet.console = true # Print in server console
  Bullet.rails_logger = true # Add to Rails.logger
  Bullet.bullet_logger = true # Log to bullet.log file
  Bullet.add_footer = Rails.env.development? # Add footer with detected issues
  Bullet.raise         = Rails.env.test? # raise an error if n+1 query occurs
  
  # Disable specific checks if needed
  # Bullet.unused_eager_loading_enable = false
  # Bullet.counter_cache_enable = false
  
  # Only show N+1 queries (most important)
  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = true
  Bullet.counter_cache_enable = true
  
  # Add safelists for test environment only - associations are actually used but test data creates false warnings
  # if Rails.env.test?
  # end
  
  # Add safelist for loan requests - requestable preparation association
  # Bullet.add_safelist type: :n_plus_one_query, class_name: "Requestable", association: :preparation
  
end
