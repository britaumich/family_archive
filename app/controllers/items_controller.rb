class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy]

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
    @item = Item.find(params[:id])
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

  def bulk_assign_tags_form
    authorize Item
    
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
    item_ids = params[:item_ids]&.reject(&:blank?)
    tag_ids = params[:tag_ids]&.reject(&:blank?)

    if item_ids.blank?
      redirect_to bulk_assign_tags_form_items_path, alert: t('forms.flash.no_items_selected')
      return
    end

    if tag_ids.blank?
      redirect_to bulk_assign_tags_form_items_path, alert: t('forms.flash.no_tags_selected') 
      return
    end

    # Find items and authorize each
    items = Item.where(id: item_ids)
    items.each { |item| authorize item, :edit? }
    
    tags = Tag.where(id: tag_ids)
    
    assigned_count = 0
    items.each do |item|
      tags.each do |tag|
        # Only create association if it doesn't already exist
        unless item.tagables.exists?(tag: tag)
          item.tagables.create(tag: tag)
          assigned_count += 1
        end
      end
    end

    if assigned_count > 0
      redirect_to bulk_assign_tags_form_items_path, notice: t('forms.flash.tags_assigned_to_items', count: assigned_count, items: items.count, tags: tags.count)
    else
      redirect_to bulk_assign_tags_form_items_path, notice: t('forms.flash.tags_already_assigned')
    end
  end

  def bulk_remove_tags
    item_ids = params[:item_ids]&.reject(&:blank?)
    tag_ids = params[:tag_ids]&.reject(&:blank?)

    if item_ids.blank?
      redirect_to bulk_assign_tags_form_items_path, alert: t('forms.flash.no_items_selected')
      return
    end

    if tag_ids.blank?
      redirect_to bulk_assign_tags_form_items_path, alert: t('forms.flash.no_tags_selected') 
      return
    end

    # Find items and authorize each
    items = Item.where(id: item_ids)
    items.each { |item| authorize item, :edit? }
    
    tags = Tag.where(id: tag_ids)
    
    removed_count = 0
    items.each do |item|
      tags.each do |tag|
        # Remove association if it exists
        tagable = item.tagables.find_by(tag: tag)
        if tagable
          tagable.destroy
          removed_count += 1
        end
      end
    end

    if removed_count > 0
      redirect_to bulk_assign_tags_form_items_path, notice: t('forms.flash.tags_removed_from_items', count: removed_count, items: items.count, tags: tags.count)
    else
      redirect_to bulk_assign_tags_form_items_path, notice: t('forms.flash.no_tags_removed')
    end
  rescue Pundit::NotAuthorizedError
    redirect_to bulk_assign_tags_form_items_path, alert: t('forms.flash.unauthorized')
  end

  private

  def set_item
    @item = Item.find(params.expect(:id))
  end

  def item_params
    params.expect(item: [:item_type, :file, :caption])
  end
end
