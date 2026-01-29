class TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy]

  # GET /tags or /tags.json
  def index
    @tag = Tag.new
    @tags = if params[:search].present?
              Tag.where('name ILIKE :search', search: "%#{params[:search]}%").order(:name)
            else
              Tag.order(:name)
            end
    authorize @tags
  end

  # GET /tags/1 or /tags/1.json
  def show
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      flash.now[:notice] = t('forms.flash.tag_created')
      @tag = Tag.new
      @tags = Tag.order(:name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: t('forms.flash.tag_updated'), status: :see_other }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    if @tag.destroy
      @tags = Tag.all.order(:name)
      @tag = Tag.new
      flash.now[:notice] = t('forms.flash.tag_deleted')
    else
      @tags = Tag.all.order(:name)
      flash.now[:notice] = t('forms.flash.error_deleting_tag')
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def tag_params
    params.expect(tag: [:name])
  end
end
