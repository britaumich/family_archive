class FamiliesController < ApplicationController
  before_action :set_family, only: %i[ edit update destroy ]

  # GET /families or /families.json
  def index
    @family = Family.new
    @families = Family.all
    authorize @families
  end

  # GET /families/new
  def new
    @family = Family.new
  end

  # GET /families/1/edit
  def edit
  end

  # POST /families or /families.json
  def create
    @family = Family.new(family_params)
    authorize @family
    if @family.save
      flash.now[:notice] = t('forms.flash.family_created')
      @family = Family.new
      @families = Family.all
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to families_path, notice: t('forms.flash.family_created') }
      end
    else
      @families = Family.all
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /families/1 or /families/1.json
  def update
    respond_to do |format|
      if @family.update(family_params)
        format.html { redirect_to families_path, notice: t('forms.flash.family_updated'), status: :see_other }
        format.json { render :show, status: :ok, location: @family }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @family.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /families/1 or /families/1.json
  def destroy
    if @family.destroy
      @families = Family.all
      @family = Family.new
      flash.now[:notice] = t('forms.flash.family_deleted')
    else
      @families = Family.all
      # Get error message before creating new instance
      error_msg = @family.errors.full_messages.to_sentence
      error_msg = t('forms.flash.cannot_delete_family_with_tags') if error_msg.blank?
      @family = Family.new
      flash.now[:alert] = t('forms.flash.error_deleting_family', error_message: error_msg)
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to families_path }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_family
      @family = Family.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def family_params
      params.expect(family: [:name_en, :name_ru])
    end
end
