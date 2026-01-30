class TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy]

  # GET /tags or /tags.json
  def index
    @tag = Tag.new
    @tag_types = TagType.order(:name)
    @tags = if params[:search].present?
              Tag.left_joins(:tag_type)
                 .where('tags.name ILIKE :search', search: "%#{params[:search]}%")
                 .order('tag_types.name ASC NULLS LAST, tags.name ASC')
            else
              Tag.left_joins(:tag_type)
                 .order('tag_types.name ASC NULLS LAST, tags.name ASC')
            end
    authorize @tags
  end

  # GET /tags/1 or /tags/1.json
  def show
  end

  # GET /tags/new
  def new
    @tag = Tag.new
    @tag_types = TagType.order(:name)
  end

  # GET /tags/1/edit
  def edit
    @tag_types = TagType.order(:name)
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      flash.now[:notice] = t('forms.flash.tag_created')
      @tag = Tag.new
      @tags = Tag.order(:name)
      @tag_types = TagType.order(:name)
    else
      @tag_types = TagType.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to tags_path, notice: t('forms.flash.tag_updated'), status: :see_other }
        format.json { render :show, status: :ok, location: @tag }
      else
        @tag_types = TagType.order(:name)
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
      @tag_types = TagType.order(:name)
      flash.now[:notice] = t('forms.flash.tag_deleted')
    else
      @tags = Tag.all.order(:name)
      @tag_types = TagType.order(:name)
      flash.now[:notice] = t('forms.flash.error_deleting_tag')
    end
    render :index
  end

  # PATCH /tags/bulk_assign
  def bulk_assign
    tag_ids = params[:tag_ids]&.reject(&:blank?)
    tag_type_id = params[:tag_type_id].presence
    
    if tag_ids&.any?
      Tag.where(id: tag_ids).update_all(tag_type_id: tag_type_id)
      flash.now[:notice] = t('forms.flash.tags_assigned_to_type')
    else
      flash.now[:alert] = t('forms.flash.no_tags_selected')
    end
    
    @tag = Tag.new
    @tag_types = TagType.order(:name)
    @tags = Tag.order(:name)
    
    render :index
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def tag_params
    params.expect(tag: [:name, :tag_type_id])
  end
end
