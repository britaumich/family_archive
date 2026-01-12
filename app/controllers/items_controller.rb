class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show ]

  def index
  end

  def show  
    @item = Item.find(params[:id])
  end

  def upoad_multiple
  end

  private
    def set_item
      @item = Item.find(params[:id])
    end

end
