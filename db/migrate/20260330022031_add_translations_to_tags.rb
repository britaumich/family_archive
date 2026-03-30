class AddTranslationsToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :name_translations, :json, default: {}
    
    # Migrate existing names to English
    reversible do |dir|
      dir.up do
        Tag.reset_column_information
        Tag.find_each do |tag|
          migration_tag = Class.new(ActiveRecord::Base) do
            self.table_name = 'tags'
          end
          migration_tag.reset_column_information
          migration_tag.find_each do |tag|
            tag.update_column(:name_translations, { 'en' => tag.name })
          end
        end
      end
    end
  end
end
