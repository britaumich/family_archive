class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy assign_tags remove_tags add_bestof]

  def index
    @tags_by_type = set_tags_by_type
    @selected_tags = []

    # Filter by multiple tags if specified
    if params[:tags].present?
      tag_ids = params[:tags].reject(&:blank?).map(&:to_i)
      @selected_tags = Tag.includes(:items).where(id: tag_ids)

      if tag_ids.any?
        # AND logic: items must have ALL selected tags
        if params[:filter_type] == 'all'
          # Use subquery to find items with all required tags
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .group('items.id')
                         .having('COUNT(DISTINCT tags.id) = ?', tag_ids.length)
                         .pluck('items.id')
          items = Item.includes(:tags)
                       .where(id: item_ids)
                       .left_joins(tags: :tag_type)
                       .group('items.id')
                       .order(Arel.sql("MAX(CASE WHEN tag_types.name = 'year' THEN tags.name END) DESC NULLS LAST, items.created_at DESC"))
        else
          # OR logic (default): items must have ANY of the selected tags
          item_ids = Item.joins(:tags)
                      .where(tags: { id: tag_ids })
                      .distinct
                      .pluck(:id)
          items = Item.includes(:tags)
                       .where(id: item_ids)
                       .left_joins(tags: :tag_type)
                       .group('items.id')
                       .order(Arel.sql("MAX(CASE WHEN tag_types.name = 'year' THEN tags.name END) DESC NULLS LAST, items.created_at DESC"))
        end
      else
        items = Item.includes(:tags)
                     .left_joins(tags: :tag_type)
                     .group('items.id')
                     .order(Arel.sql("MAX(CASE WHEN tag_types.name = 'year' THEN tags.name END) DESC NULLS LAST, items.created_at DESC"))
      end
    else
      items = Item.includes(:tags)
                   .left_joins(tags: :tag_type)
                   .group('items.id')
                   .order(Arel.sql("MAX(CASE WHEN tag_types.name = 'year' THEN tags.name END) DESC NULLS LAST, items.created_at DESC"))
    end
    @items = items.includes(file_attachment: :blob).page(params[:page]).per(params[:per].presence || Kaminari.config.default_per_page)
    
    authorize @items
  end

  def family_pictures
    fail
  end

  def show
    # Prepare tags organized by type for assignment
    @tags_by_type = set_tags_by_type
    authorize @item
  end

  def edit
    @tags_by_type = set_tags_by_type
    authorize @item
  end

  def update
    authorize @item
    if @item.update(item_params)
      # Update tags if provided
      if params[:tag_ids].present?
        @item.tags.clear
        params[:tag_ids].each do |tag_id|
          tag = Tag.find(tag_id) if tag_id.present?
          @item.tags << tag if tag
        end
      end
      redirect_to @item, notice: t('forms.flash.item_updated')
    else
      @tags_by_type = set_tags_by_type
      render :edit
    end
  end

  def destroy
    authorize @item
    @item.destroy
    redirect_to items_path, notice: t('forms.flash.item_deleted')
  end

  def upload_files_page
    authorize Item
    @tags = Tag.order(:name)
  end

  def upload_files
    if params[:files].present? && params[:tag_ids].present?
      params[:files].each do |file|
        @item = Item.new(item_type: params[:item_type])
        @item.file.attach(file)
        next unless @item.save

        params[:tag_ids].each do |tag_id|
          tag = Tag.find(tag_id)
          @item.tags << tag
        end
      end
      flash[:notice] = t('forms.flash.files_uploaded')
      redirect_to upload_files_page_path
    else
      flash[:alert] = t('forms.flash.please_select_files_and_tags')
      redirect_to upload_files_page_path
    end
  end

  def editing_tags_page
    authorize Item, :editing_tags_page?
    
    @tags_by_type = set_tags_by_type
    @selected_tags = []
    # Filter by multiple tags if specified
    if params[:tags].present?
      tag_ids = params[:tags].reject(&:blank?).map(&:to_i)
      @selected_tags = Tag.includes(:tag_type).where(id: tag_ids)

      if tag_ids.any?
        # AND logic: items must have ALL selected tags
        if params[:filter_type] == 'all'
          # Use subquery to find items with all required tags
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .group('items.id')
                         .having('COUNT(DISTINCT tags.id) = ?', tag_ids.length)
                         .pluck('items.id')
          items = Item.includes(:tags)
                       .where(id: item_ids)
                       .order(created_at: :desc)
        else
          # OR logic (default): items must have ANY of the selected tags
          item_ids = Item.joins(:tags)
                      .where(tags: { id: tag_ids })
                      .distinct
                      .pluck(:id)
          items = Item.includes(:tags)
                       .where(id: item_ids)
                       .order(created_at: :desc)
        end
      else
        items = Item.includes(:tags).order(created_at: :desc).limit(15)
      end
    else
      items = Item.includes(:tags).order(created_at: :desc).limit(15)
    end
    @items = items.includes(file_attachment: :blob)
    
    respond_to do |format|
      format.html
      format.turbo_stream { 
        Rails.logger.info "DEBUG: Selected tags in turbo_stream: #{@selected_tags.map(&:name)}"
        Rails.logger.info "DEBUG: Items count in turbo_stream: #{@items.count}"
        
        # Build turbo_stream updates for each tag type's badges
        turbo_updates = [
          turbo_stream.update("filter-badges", partial: "filter_badges"),
          turbo_stream.update("items-list", partial: "editing_items_list"),
          turbo_stream.replace('tags-selection-panel', partial: 'tag_selection_panel')
        ]
        
        # Add updates for each tag type's individual badges
        @tags_by_type.each do |tag_type, tags|
          badge_id = "badges-for-#{tag_type&.id || 'no-type'}"
          turbo_updates << turbo_stream.update(badge_id, partial: "tag_type_badges", locals: { tag_type: tag_type })
        end
        
        render turbo_stream: turbo_updates
      }
    end
  end

  def bulk_assign_tags
    authorize Item
    item_ids = params[:item_ids]&.reject(&:blank?)&.map(&:to_i)
    tag_ids = params[:tag_ids]&.reject(&:blank?)&.map(&:to_i)

    if tag_ids.blank?
      respond_to do |format|
        format.turbo_stream {
          flash[:alert] = t('forms.flash.no_tags_selected')
          render turbo_stream: turbo_stream.update('flash', partial: 'layouts/notification')
        }
        format.html { redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_tags_selected') }
      end
      return
    end

    if item_ids.blank?
      respond_to do |format|
        format.turbo_stream {
          flash[:alert] = t('forms.flash.no_items_selected')
          render turbo_stream: turbo_stream.update('flash', partial: 'layouts/notification')
        }
        format.html { redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_items_selected') }
      end
      return
    end

    # Find items, preload tags to avoid N+1
    @items = Item.where(id: item_ids).includes(:tags, file_attachment: :blob)
    # Load all candidate tags once
    candidate_tags = Tag.where(id: tag_ids).index_by(&:id)
    assigned_count = 0
    @items.each do |item|
      # Use preloaded tags to avoid additional queries
      existing_tag_ids = item.tags.map(&:id)
      new_tag_ids = tag_ids - existing_tag_ids
      if new_tag_ids.any?
        # Get new tags from the preloaded hash
        new_tags = new_tag_ids.map { |id| candidate_tags[id] }.compact
        item.tags << new_tags
        assigned_count += new_tag_ids.length
      end
    end

    # Refresh items with updated tags
    @selected_item_ids = item_ids
    
    # Prepare tags organized by type for assignment panel
    @tags_by_type = set_tags_by_type

    respond_to do |format|
      format.turbo_stream {
        flash_message = assigned_count > 0 ? t('forms.flash.tags_assigned_to_items') : t('forms.flash.tags_already_assigned')
        flash[:notice] = flash_message
        render turbo_stream: [
          turbo_stream.update("items-list", partial: "editing_items_list", locals: { selected_item_ids: @selected_item_ids }),
          turbo_stream.update('flash', partial: 'layouts/notification'),
          turbo_stream.replace('tags-selection-panel', partial: 'tag_selection_panel')
        ]
      }
      format.html {
        if assigned_count > 0
          redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_assigned_to_items')
        else
          redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_already_assigned')
        end
      }
    end
  end

  def bulk_remove_tags
    authorize Item
    item_ids = params[:item_ids]&.reject(&:blank?)&.map(&:to_i)
    tag_ids = params[:tag_ids]&.reject(&:blank?)&.map(&:to_i)

    if item_ids.blank?
      respond_to do |format|
        format.turbo_stream {
          flash[:alert] = t('forms.flash.no_items_selected')
          render turbo_stream: turbo_stream.update('flash', partial: 'layouts/notification')
        }
        format.html { redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_items_selected') }
      end
      return
    end

    if tag_ids.blank?
      respond_to do |format|
        format.turbo_stream {
          flash[:alert] = t('forms.flash.no_tags_selected')
          render turbo_stream: turbo_stream.update('flash', partial: 'layouts/notification')
        }
        format.html { redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_tags_selected') }
      end
      return
    end

    # Find items, preload tags to avoid N+1
    @items = Item.where(id: item_ids).includes(:tags, file_attachment: :blob)
    
    # Load all candidate tags once
    candidate_tags = Tag.where(id: tag_ids).index_by(&:id)
    
    removed_count = 0
    @items.each do |item|
      # Use preloaded tags to avoid additional queries
      existing_tag_ids = item.tags.map(&:id)
      tags_to_remove_ids = tag_ids & existing_tag_ids
      
      if tags_to_remove_ids.any?
        # Get tags to remove from the preloaded hash
        tags_to_remove = tags_to_remove_ids.map { |id| candidate_tags[id] }.compact
        item.tags.delete(tags_to_remove)
        removed_count += tags_to_remove_ids.length
      end
    end

    # Refresh items with updated tags
    @selected_item_ids = item_ids
    
    # Prepare tags organized by type for assignment panel
    @tags_by_type = set_tags_by_type

    respond_to do |format|
      format.turbo_stream {
        flash_message = removed_count > 0 ? t('forms.flash.tags_removed_from_items') : t('forms.flash.no_tags_removed')
        flash[:notice] = flash_message
        render turbo_stream: [
          turbo_stream.update("items-list", partial: "editing_items_list", locals: { selected_item_ids: @selected_item_ids }),
          turbo_stream.update('flash', partial: 'layouts/notification'),
          turbo_stream.replace('tags-selection-panel', partial: 'tag_selection_panel')
        ]
      }
      format.html {
        if removed_count > 0
          redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_removed_from_items')
        else
          redirect_to editing_tags_page_items_path, notice: t('forms.flash.no_tags_removed')
        end
      }
    end
  end

  def assign_tags
    authorize @item
    
    if params[:tag_ids].blank?
      redirect_to @item, alert: t('forms.flash.no_tags_selected')
      return
    end
    
    tag_ids = params[:tag_ids].reject(&:blank?).map(&:to_i)
    
    # Validate that the provided tag IDs exist
    valid_tag_ids = Tag.where(id: tag_ids).pluck(:id)
    
    if valid_tag_ids.empty?
      redirect_to @item, alert: t('forms.flash.invalid_tags_selected')
      return
    end
    
    # Find tags that aren't already assigned to avoid duplicates
    new_tag_ids = valid_tag_ids - @item.tag_ids
    
    if new_tag_ids.any?
      # Only load and assign the new tags
      new_tags = Tag.where(id: new_tag_ids)
      @item.tags << new_tags
      redirect_to @item, notice: t('forms.flash.tags_assigned_to_item')
    else
      redirect_to @item, notice: t('forms.flash.tags_already_assigned')
    end
  end

  def remove_tags
    authorize @item
    
    if params[:tag_ids].blank?
      redirect_to @item, alert: t('forms.flash.no_tags_selected')
      return
    end
    
    tag_ids = params[:tag_ids].reject(&:blank?).map(&:to_i)
    
    # Validate that the provided tag IDs exist
    valid_tag_ids = Tag.where(id: tag_ids).pluck(:id)
    
    if valid_tag_ids.empty?
      redirect_to @item, alert: t('forms.flash.invalid_tags_selected')
      return
    end
    
    # Find tags that are currently assigned to the item
    existing_tag_ids = tag_ids & @item.tag_ids
    
    if existing_tag_ids.any?
      # Only load and remove the existing tags
      existing_tags = Tag.where(id: existing_tag_ids)
      @item.tags.delete(existing_tags)
      redirect_to @item, notice: t('forms.flash.tags_removed_from_item')
    else
      redirect_to @item, notice: t('forms.flash.no_tags_to_remove')
    end
  end

  def apply_filters_to_edit_tags
    authorize Item, :editing_tags_page?
    
    apply_current_filters

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("items-list", partial: "editing_items_list") }
      format.html { redirect_to editing_tags_page_items_path(params.permit(:tags, :filter_type)) }
    end
  end

  def add_bestof
    authorize @item
    bestof_tag = Tag.find_by(name: 'bestof')
    # unless bestof_tag.present?
    #   redirect_to @item, alert: t('forms.flash.bestof_tag_not_found')
    #   return
    # end
    
    if @item.tags.exists?(name: 'bestof')
      # Remove the bestof tag if it exists
      @item.tags.delete(bestof_tag)
    else
      # Add the bestof tag if it doesn't exist
      @item.tags << bestof_tag if bestof_tag
    end
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "picture_#{@item.id}",
          partial: "items/item_card",
          locals: { item: @item }
        )
      end
      format.html do
        redirect_to @item
      end
    end
  
  end

  private

  def apply_current_filters
    @tags_by_type = set_tags_by_type
    @selected_tags = []

    # Filter by multiple tags if specified
    if params[:tags].present?
      tag_ids = params[:tags].reject(&:blank?).map(&:to_i)
      @selected_tags = Tag.includes(:items).where(id: tag_ids)

      if tag_ids.any?
        # AND logic: items must have ALL selected tags
        if params[:filter_type] == 'all'
          # Use subquery to find items with all required tags
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .group('items.id')
                         .having('COUNT(DISTINCT tags.id) = ?', tag_ids.length)
                         .pluck('items.id')
        else
          # OR logic (default): items must have ANY of the selected tags
          # Get item IDs that match the filter
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .distinct
                         .pluck(:id)
        end
        
        # Load the filtered items without includes to avoid tag filtering
        @items = Item.where(id: item_ids)
                     .with_attached_file
                     .order(created_at: :desc)
        
        # Load all tags for each item separately to avoid filtering
        @items = @items.map do |item|
          item.association(:tags).reset
          item
        end
        
        # Preload tags for all items at once
        ActiveRecord::Associations::Preloader.new.preload(@items, :tags)
      else
        @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
      end
    else
      @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
    end
    
    # Also prepare tags organized by type for assignment
    @tags_without_type = Tag.where(tag_type: nil)
  end

  def set_tags_by_type
    Tag.left_outer_joins(:tag_type, :items)
      .includes(:tag_type)
      .group('tags.id, tag_types.id')
      .having('COUNT(items.id) > 0')
      .order('tags.name')
      .group_by(&:tag_type)
      .sort_by { |tag_type, _| tag_type&.translated_name || '' }
  end

  def set_item
    @item = Item.includes(tags: :tag_type, file_attachment: :blob).find(params.expect(:id))
  end

  def item_params
    params.expect(item: [:item_type, :file, :caption])
  end
end
