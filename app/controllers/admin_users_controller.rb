class AdminUsersController < ApplicationController
  before_action :set_admin_user, only: %i[ edit update destroy ]

  # GET /admin_users or /admin_users.json
  def index
    @admin_users = AdminUser.all
    authorize @admin_users
  end

  # GET /admin_users/new
  def new
    @admin_user = AdminUser.new
    authorize @admin_user
  end

  # GET /admin_users/1/edit
  def edit
  end

  # POST /admin_users or /admin_users.json
  def create
    @admin_user = AdminUser.new(admin_user_params)
    authorize @admin_user
    respond_to do |format|
      if @admin_user.save
        format.html { redirect_to admin_users_url, notice: t('forms.messages.Admin user was successfully added') }
        format.json { render :show, status: :created, location: @admin_user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin_users/1 or /admin_users/1.json
  def update
    respond_to do |format|
      if @admin_user.update(admin_user_params)
        format.html { redirect_to admin_users_url, notice: t('forms.messages.Admin user was successfully updated') }
        format.json { render :show, status: :ok, location: @admin_user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_users/1 or /admin_users/1.json
  def destroy
    if @admin_user.destroy
      flash.now[:notice] = t('forms.messages.Admin user was successfully deleted')
    else
      flash.now[:alert] = t('text.Admin user could not be deleted ')
      flash.now[:alert] += @admin_user.errors.full_messages.join(', ')
    end
    @admin_users = AdminUser.order(:email)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [ turbo_stream.replace('admin_users', partial: 'admin_users/admin_users_list'),
                                turbo_stream.update('flash', partial: 'layouts/notification') ]
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_user
      @admin_user = AdminUser.find(params.expect(:id))
      authorize @admin_user
    end

    # Only allow a list of trusted parameters through.
    def admin_user_params
      params.expect(admin_user: [ :email ])
    end
end
