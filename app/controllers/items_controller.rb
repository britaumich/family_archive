class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy]

  def index
    @tags = Tag.all.order(:name)
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
      redirect_to @item, notice: 'Item was successfully updated.'
    else
      @tags = Tag.order(:name)
      render :edit
    end
  end

  def destroy
    authorize @item
    @item.destroy
    redirect_to items_path, notice: 'Item was successfully deleted.'
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
      flash[:notice] = 'Files uploaded successfully.'
      redirect_to upload_files_page_path
    else
      flash[:alert] = 'Please select files and at least one tag.'
      redirect_to upload_files_page_path
    end
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:item_type, :file, :caption)
  end
end
