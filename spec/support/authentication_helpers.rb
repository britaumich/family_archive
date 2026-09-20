module AuthenticationHelpers
  # Creates a User + matching AdminUser (role: :admin/:editor) and signs in via the session form.
  def sign_in_as(role: :admin)
    user = create(:user, email_address: "#{role}_#{SecureRandom.hex(4)}@example.com", password: 'password')
    create(:admin_user, email: user.email_address, role: role)
    post session_path, params: { email_address: user.email_address, password: 'password' }
    user
  end
end
