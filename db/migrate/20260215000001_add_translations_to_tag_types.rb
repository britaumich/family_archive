class AddTranslationsToTagTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :tag_types, :name_translations, :json, default: {}
    
    # Migrate existing names to English
    reversible do |dir|
      dir.up do
        TagType.reset_column_information
        TagType.find_each do |tag_type|
          tag_type.update_column(:name_translations, { 'en' => tag_type.name })
        end
      end
    end
  end
end