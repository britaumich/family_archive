class AddTagCountToFamily < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :tags_count, :integer, default: 0, null: false
  end
end
