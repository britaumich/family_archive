class TagTypesController < ApplicationController
  before_action :set_tag_type, only: %i[edit update destroy]

  # GET /tag_types or /tag_types.json
  def index
    @tag_type = TagType.new
    @tag_types = if params[:search].present?
                   search_term = "%#{params[:search]}%"
                   search_clause = "(tag_types.name_translations->>'en' ILIKE ? OR tag_types.name_translations->>'ru' ILIKE ? OR tag_types.name ILIKE ?)"
                   ordered_tag_types.where(search_clause, search_term, search_term, search_term)
                 else
                   ordered_tag_types
                 end
    authorize @tag_types
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
      @tag_types = ordered_tag_types
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to tag_types_path, notice: t('forms.flash.tag_type_created') }
      end
    else
      @tag_types = ordered_tag_types
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tag_types/1 or /tag_types/1.json
  def update
    respond_to do |format|
      if @tag_type.update(tag_type_params)
        format.html { redirect_to tag_types_path, notice: t('forms.flash.tag_type_updated'), status: :see_other }
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
      @tag_types = ordered_tag_types
      @tag_type = TagType.new
      flash.now[:notice] = t('forms.flash.tag_type_deleted')
    else
      @tag_types = ordered_tag_types
      # Get error message before creating new instance
      error_msg = @tag_type.errors.full_messages.to_sentence
      error_msg = t('forms.flash.cannot_delete_tag_type_with_tags') if error_msg.blank?
      @tag_type = TagType.new
      flash.now[:alert] = t('forms.flash.error_deleting_tag_type', error_message: error_msg)
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to tag_types_path }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag_type
    @tag_type = TagType.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def tag_type_params
    params.expect(tag_type: [:name_en, :name_ru])
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
end
