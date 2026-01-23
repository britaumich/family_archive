class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    # if AdminUser.find_by(email: @user.email_address).present?
      if @user.save
        start_new_session_for(@user)
        redirect_to root_url, notice: t('forms.messages.Registered successfully')
      else
        render :new, status: :unprocessable_entity
      end
    # else
    #   redirect_to new_registration_path, alert: t('forms.messages.Email address is not allowed to register')
    # end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
