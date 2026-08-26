class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.valid? && admin_user_for_email(@user.email_address).nil?
       @user.errors.add(:base, t('auth.registration_not_allowed'))
      render :new, status: :unprocessable_entity
      return
    end

    if @user.save
      if start_new_session_for(@user)
        redirect_to root_url, notice: t('forms.flash.registered_successfully')
      else
        terminate_session
        @user.errors.add(:base, t('auth.login_not_allowed'))
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @user.errors.add(:email_address, t('activerecord.errors.models.user.attributes.email_address.taken'))
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
