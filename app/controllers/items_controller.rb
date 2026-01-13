class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show ]

  def index
    @items = Item.includes(:tags).with_attached_file.order(created_at: :desc)
    @tags = Tag.all.order(:name)
    
    # Filter by tag if specified
    if params[:tag].present?
      @selected_tag = Tag.find(params[:tag])
      @items = @items.joins(:tags).where(tags: { id: params[:tag] })
    end
  end

  def show  
    @item = Item.find(params[:id])
  end

  def upload_files_page
    @tags = Tag.order(:name)
  end

  def upload_files
    if params[:files].present? && params[:tag_ids].present?
      params[:files].each do |file|
        @item = Item.new(item_type: params[:item_type])
        @item.file.attach(file)
        if @item.save
          params[:tag_ids].each do |tag_id|
            tag = Tag.find(tag_id)
            @item.tags << tag
          end
        end
      end
      flash[:notice] = "Files uploaded successfully."
      redirect_to upload_files_page_path
    else
      flash[:alert] = "Please select files and at least one tag."
      redirect_to upload_files_page_path
    end
  end

  private
    def set_item
      @item = Item.find(params[:id])
    end

end
