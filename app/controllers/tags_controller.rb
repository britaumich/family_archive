class TagsController < ApplicationController
  before_action :set_tag, only: %i[edit update destroy]

  # GET /tags or /tags.json
  def index
    @tag = Tag.new
    @tag_types = ordered_tag_types
    @tags = if params[:search].present?
              search_term = "%#{params[:search]}%"
              search_clause = "(tags.name_translations->>'en' ILIKE ? OR tags.name_translations->>'ru' ILIKE ? OR tags.name ILIKE ?)"
              ordered_tags.where(search_clause, search_term, search_term, search_term)
            else
              ordered_tags
            end
    authorize @tags
  end

  # GET /tags/new
  def new
    @tag = Tag.new
    @tag_types = ordered_tag_types
  end

  # GET /tags/1/edit
  def edit
    @tag_types = ordered_tag_types
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)
    authorize @tag
    if @tag.save
      flash.now[:notice] = t('forms.flash.tag_created')
      @tag = Tag.new
      @tags = ordered_tags
      @tag_types = ordered_tag_types
    else
      @tag_types = ordered_tag_types
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
        @tag_types = ordered_tag_types
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    if @tag.destroy
      @tags = ordered_tags
      @tag = Tag.new
      @tag_types = ordered_tag_types
      flash.now[:notice] = t('forms.flash.tag_deleted')
    else
      @tags = ordered_tags
      @tag_types = ordered_tag_types
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
    @tag_types = ordered_tag_types
    @tags = ordered_tags
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

  # Safely get current locale with whitelist to prevent SQL injection
  def safe_locale
    allowed_locales = %w[en ru]
    locale = I18n.locale.to_s
    allowed_locales.include?(locale) ? locale : 'en'
  end

  # Get tag types ordered by translated name with safe locale interpolation
  def ordered_tag_types
    locale = safe_locale  # Already whitelisted, safe to interpolate
    TagType.order(Arel.sql("COALESCE(name_translations->>'#{locale}', name_translations->>'en', name)"))
  end

  # Get tags ordered by translated name with safe locale interpolation
  def ordered_tags
    locale = safe_locale  # Already whitelisted, safe to interpolate
    order_clause = Arel.sql("COALESCE(tag_types.name_translations->>'#{locale}', tag_types.name_translations->>'en', tag_types.name) ASC NULLS LAST, COALESCE(tags.name_translations->>'#{locale}', tags.name_translations->>'en', tags.name) ASC")
    Tag.left_outer_joins(:tag_type).includes(:tag_type).order(order_clause)
  end
end
