class RemoveUnusedTranslationColumnsFromTagTypes < ActiveRecord::Migration[8.1]
  def change
    # Remove unused indexes first
    remove_index :tag_types, :name_en if index_exists?(:tag_types, :name_en)
    remove_index :tag_types, :name_ru if index_exists?(:tag_types, :name_ru)
    
    # Remove unused columns (we're using JSON approach instead)
    remove_column :tag_types, :name_en, :string if column_exists?(:tag_types, :name_en)
    remove_column :tag_types, :name_ru, :string if column_exists?(:tag_types, :name_ru)
  end
end