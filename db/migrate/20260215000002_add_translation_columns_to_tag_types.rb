# Alternative approach - separate columns
# Run this instead of the JSON approach if you prefer individual columns
class AddTranslationColumnsToTagTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :tag_types, :name_en, :string
    add_column :tag_types, :name_ru, :string
    
    # Migrate existing names to English
    reversible do |dir|
      dir.up do
        TagType.reset_column_information
        TagType.find_each do |tag_type|
          tag_type.update_column(:name_en, tag_type.name)
        end
      end
    end
    
    # Add indexes for query performance
    add_index :tag_types, :name_en
    add_index :tag_types, :name_ru
  end
end