class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy assign_tags remove_tags]

  def index
    @tags = Tag.includes(:tag_type).order('tag_types.name ASC NULLS LAST, tags.name ASC')
    @tags_by_type = @tags.group_by(&:tag_type)
    @selected_tags = []

    # Filter by multiple tags if specified
    if params[:tags].present?
      tag_ids = params[:tags].reject(&:blank?).map(&:to_i)
      @selected_tags = Tag.where(id: tag_ids)

      if tag_ids.any?
        # AND logic: items must have ALL selected tags
        if params[:filter_type] == 'all'
          # Use subquery to find items with all required tags
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .group('items.id')
                         .having('COUNT(DISTINCT tags.id) = ?', tag_ids.length)
                         .pluck('items.id')
          @items = Item.includes(:tags).with_attached_file
                       .where(id: item_ids)
                       .order(created_at: :desc)
        else
          # OR logic (default): items must have ANY of the selected tags
          @items = Item.includes(:tags).with_attached_file
                       .joins(:tags)
                       .where(tags: { id: tag_ids })
                       .distinct
                       .order(created_at: :desc)
        end
      else
        @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
      end
    else
      @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
    end
    authorize @items
  end

  def show
    # Prepare tags organized by type for assignment
    @assignment_tags_by_type = Tag.joins(:tag_type).includes(:tag_type)
                               .group_by(&:tag_type)
                               .transform_keys(&:name)
                               .sort
    authorize @item
  end

  def edit
    @tags = Tag.order(:name)
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
      @tags = Tag.order(:name)
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
    
    @tags = Tag.includes(:tag_type).order('tag_types.name ASC NULLS LAST, tags.name ASC')
    @tags_by_type = @tags.group_by(&:tag_type)
    @selected_tags = []

    # Filter by multiple tags if specified
    if params[:tags].present?
      tag_ids = params[:tags].reject(&:blank?).map(&:to_i)
      @selected_tags = Tag.where(id: tag_ids)

      if tag_ids.any?
        # AND logic: items must have ALL selected tags
        if params[:filter_type] == 'all'
          # Use subquery to find items with all required tags
          item_ids = Item.joins(:tags)
                         .where(tags: { id: tag_ids })
                         .group('items.id')
                         .having('COUNT(DISTINCT tags.id) = ?', tag_ids.length)
                         .pluck('items.id')
          @items = Item.includes(:tags).with_attached_file
                       .where(id: item_ids)
                       .order(created_at: :desc)
        else
          # OR logic (default): items must have ANY of the selected tags
          @items = Item.includes(:tags).with_attached_file
                       .joins(:tags)
                       .where(tags: { id: tag_ids })
                       .distinct
                       .order(created_at: :desc)
        end
      else
        @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
      end
    else
      @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
    end
    
    # Also prepare tags organized by type for assignment
    @assignment_tags_by_type = Tag.joins(:tag_type).includes(:tag_type)
                               .group_by(&:tag_type)
                               .transform_keys(&:name)
                               .sort
    @assignment_tags_without_type = Tag.where(tag_type: nil)
  end

  def bulk_assign_tags
    authorize Item
    item_ids = params[:item_ids]&.reject(&:blank?)&.map(&:to_i)
    tag_ids = params[:tag_ids]&.reject(&:blank?)&.map(&:to_i)

    if item_ids.blank?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_items_selected')
      return
    end

    if tag_ids.blank?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_tags_selected') 
      return
    end

    # Find items and authorize each, preload tags to avoid N+1
    items = Item.where(id: item_ids).includes(:tags)
    items.each { |item| authorize item, :edit? }
    
    # Validate that the provided tag IDs exist and load them once
    valid_tag_ids = Tag.where(id: tag_ids).pluck(:id)
    
    if valid_tag_ids.empty?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.invalid_tags_selected')
      return
    end
    
    # Load all candidate tags once
    candidate_tags = Tag.where(id: valid_tag_ids).index_by(&:id)
    
    assigned_count = 0
    items.each do |item|
      # Use preloaded tags to avoid additional queries
      existing_tag_ids = item.tags.map(&:id)
      new_tag_ids = valid_tag_ids - existing_tag_ids
      
      if new_tag_ids.any?
        # Get new tags from the preloaded hash
        new_tags = new_tag_ids.map { |id| candidate_tags[id] }.compact
        item.tags << new_tags
        assigned_count += new_tag_ids.length
      end
    end

    if assigned_count > 0
      redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_assigned_to_items')
    else
      redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_already_assigned')
    end
  end

  def bulk_remove_tags
    authorize Item
    item_ids = params[:item_ids]&.reject(&:blank?)&.map(&:to_i)
    tag_ids = params[:tag_ids]&.reject(&:blank?)&.map(&:to_i)

    if item_ids.blank?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_items_selected')
      return
    end

    if tag_ids.blank?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.no_tags_selected') 
      return
    end

    # Find items and authorize each, preload tags to avoid N+1
    items = Item.where(id: item_ids).includes(:tags)
    items.each { |item| authorize item, :edit? }
    
    # Validate that the provided tag IDs exist and load them once
    valid_tag_ids = Tag.where(id: tag_ids).pluck(:id)
    
    if valid_tag_ids.empty?
      redirect_to editing_tags_page_items_path, alert: t('forms.flash.invalid_tags_selected')
      return
    end
    
    # Load all candidate tags once
    candidate_tags = Tag.where(id: valid_tag_ids).index_by(&:id)
    
    removed_count = 0
    items.each do |item|
      # Use preloaded tags to avoid additional queries
      existing_tag_ids = item.tags.map(&:id)
      tags_to_remove_ids = valid_tag_ids & existing_tag_ids
      
      if tags_to_remove_ids.any?
        # Get tags to remove from the preloaded hash
        tags_to_remove = tags_to_remove_ids.map { |id| candidate_tags[id] }.compact
        item.tags.delete(tags_to_remove)
        removed_count += tags_to_remove_ids.length
      end
    end

    if removed_count > 0
      redirect_to editing_tags_page_items_path, notice: t('forms.flash.tags_removed_from_items')
    else
      redirect_to editing_tags_page_items_path, notice: t('forms.flash.no_tags_removed')
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
    existing_tag_ids = valid_tag_ids & @item.tag_ids
    
    if existing_tag_ids.any?
      # Only load and remove the existing tags
      existing_tags = Tag.where(id: existing_tag_ids)
      @item.tags.delete(existing_tags)
      redirect_to @item, notice: t('forms.flash.tags_removed_from_item')
    else
      redirect_to @item, notice: t('forms.flash.no_tags_to_remove')
    end
  end

  private

  def set_item
    @item = Item.find(params.expect(:id))
  end

  def item_params
    params.expect(item: [:item_type, :file, :caption])
  end
end
