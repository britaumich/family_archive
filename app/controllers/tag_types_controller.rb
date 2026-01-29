class TagTypesController < ApplicationController
  before_action :set_tag_type, only: %i[show edit update destroy]

  # GET /tag_types or /tag_types.json
  def index
    @tag_type = TagType.new
    @tag_types = if params[:search].present?
                   TagType.where('name ILIKE :search', search: "%#{params[:search]}%").order(:name)
                 else
                   TagType.order(:name)
                 end
    authorize @tag_types
  end

  # GET /tag_types/1 or /tag_types/1.json
  def show
  end

  # GET /tag_types/new
  def new
    @tag_type = TagType.new
  end

  # GET /tag_types/1/edit
  def edit
  end

  # POST /tag_types or /tag_types.json
  def create
    @tag_type = TagType.new(tag_type_params)
    authorize @tag_type
    if @tag_type.save
      flash.now[:notice] = t('forms.flash.tag_type_created')
      @tag_type = TagType.new
      @tag_types = TagType.order(:name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tag_types/1 or /tag_types/1.json
  def update
    respond_to do |format|
      if @tag_type.update(tag_type_params)
        format.html { redirect_to @tag_type, notice: t('forms.flash.tag_type_updated'), status: :see_other }
        format.json { render :show, status: :ok, location: @tag_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tag_types/1 or /tag_types/1.json
  def destroy
    if @tag_type.destroy
      @tag_types = TagType.all.order(:name)
      @tag_type = TagType.new
      flash.now[:notice] = t('forms.flash.tag_type_deleted')
    else
      @tag_types = TagType.all.order(:name)
      flash.now[:notice] = t('forms.flash.error_deleting_tag_type')
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag_type
    @tag_type = TagType.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def tag_type_params
    params.expect(tag_type: [:name])
  end
end