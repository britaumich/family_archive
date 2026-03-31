class TagsController < ApplicationController
  before_action :set_tag, only: %i[edit update destroy]

  # GET /tags or /tags.json
  def index
    @tag = Tag.new
    @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
    @tags = if params[:search].present?
              Tag.left_outer_joins(:tag_type).includes(:tag_type)
                 .where('tags.name ILIKE :search', search: "%#{params[:search]}%")
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
            else
              Tag.left_outer_joins(:tag_type).includes(:tag_type)
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
            end
    authorize @tags
  end

  # GET /tags/new
  def new
    @tag = Tag.new
    @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
  end

  # GET /tags/1/edit
  def edit
    @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      flash.now[:notice] = t('forms.flash.tag_created')
      @tag = Tag.new
      @tags = Tag.left_outer_joins(:tag_type).includes(:tag_type)
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
      @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
    else
      @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
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
        @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    if @tag.destroy
      @tags = Tag.left_joins(:tag_type)
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
      @tag = Tag.new
      @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
      flash.now[:notice] = t('forms.flash.tag_deleted')
    else
      @tags = Tag.left_joins(:tag_type)
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
      @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
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
    @tag_types = TagType.order(Arel.sql("COALESCE(name_translations->>'#{I18n.locale}', name_translations->>'en', name)"))
    @tags = Tag.left_joins(:tag_type)
                 .order(Arel.sql("COALESCE(tag_types.name_translations->>'#{I18n.locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{I18n.locale}', tags.name_translations->>'en', tags.name) ASC"))
    render :index
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def tag_params
    params.expect(tag: [:name_en, :name_ru, :tag_type_id])
  end
end
