class AddCaptionToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :caption, :string
  end
end
