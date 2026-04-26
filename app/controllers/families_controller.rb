class FamiliesController < ApplicationController
  before_action :set_family, only: %i[ edit update destroy assign_tags ]

  # GET /families or /families.json
  def index
    @family = Family.new
    @families = Family.includes(tags: :tag_type).all
    authorize @families
  end

  # GET /families/new
  def new
    @family = Family.new
  end

  # GET /families/1/edit
  def edit
    @tags = if params[:search].present?
              search_term = "%#{params[:search]}%"
              search_clause = "(tags.name_translations->>'en' ILIKE ? OR tags.name_translations->>'ru' ILIKE ? OR tags.name ILIKE ?)"
              ordered_tags.where(search_clause, search_term, search_term, search_term)
            else
              ordered_tags
            end
    @tag_types = ordered_tag_types
  end

  # POST /families or /families.json
  def create
    @family = Family.new(family_params)
    authorize @family
    if @family.save
      flash.now[:notice] = t('forms.flash.family_created')
      @family = Family.new
      @families = Family.includes(tags: :tag_type).all
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to families_path, notice: t('forms.flash.family_created') }
      end
    else
      @families = Family.includes(tags: :tag_type).all
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
      @families = Family.includes(tags: :tag_type).all
      @family = Family.new
      flash.now[:notice] = t('forms.flash.family_deleted')
    else
      @families = Family.includes(tags: :tag_type).all
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

  # PATCH /families/1/assign_tags
  def assign_tags
    tag_ids = params[:tag_ids]&.reject(&:blank?)&.map(&:to_i) || []
    
    Tag.transaction do
      # Get tags that are currently assigned to this family
      current_tag_ids = @family.tags.pluck(:id)
      
      # Determine which tags to add and remove
      tags_to_add = tag_ids - current_tag_ids
      tags_to_remove = current_tag_ids - tag_ids
      
      # Remove tags that are no longer selected
      if tags_to_remove.any?
        # Get tags being removed and their family assignments for counter cache
        Tag.where(id: tags_to_remove).update_all(family_id: nil)
        Family.update_counters(@family.id, tags_count: -tags_to_remove.count)
      end
      
      # Add newly selected tags
      if tags_to_add.any?
        # Get tags that were previously assigned to other families
        tags_being_reassigned = Tag.where(id: tags_to_add).where.not(family_id: nil)
        old_family_assignments = tags_being_reassigned.group_by(&:family_id)
        
        # Update tags to belong to this family
        Tag.where(id: tags_to_add).update_all(family_id: @family.id)
        
        # Update counter caches for old families that lost tags
        old_family_assignments.each do |old_family_id, tags|
          Family.update_counters(old_family_id, tags_count: -tags.count)
        end
        
        # Update counter cache for this family
        Family.update_counters(@family.id, tags_count: tags_to_add.count)
      end
    end
    
    # Reload the tags association to ensure fresh data for the view
    @family.tags.reload
    
    if tag_ids.any? || @family.tags.exists?
      flash[:notice] = t('forms.flash.tags_assigned_to_family')
    else
      flash[:notice] = t('families.edit.all_tags_removed')
    end
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_family_path(@family) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_family
      @family = Family.find(params.expect(:id))
      authorize @family
    end

    # Only allow a list of trusted parameters through.
    def family_params
      params.expect(family: [:name_en, :name_ru])
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
      Tag.left_outer_joins(:tag_type).includes(:tag_type, :family).order(order_clause)
    end
end
