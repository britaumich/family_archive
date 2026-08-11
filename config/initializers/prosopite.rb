# Prosopite configuration for N+1 query detection
# Replaces Bullet gem — works better with Rails 8
if defined?(Prosopite)
  # Log N+1 detections to both development.log and log/prosopite.log.
  Prosopite.rails_logger = true
  Prosopite.prosopite_logger = true
  Prosopite.stderr_logger = true
  Prosopite.raise = Rails.env.test?
end
