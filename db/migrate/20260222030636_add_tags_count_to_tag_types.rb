class AddTagsCountToTagTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :tag_types, :tags_count, :integer, default: 0, null: false
    TagType.reset_column_information
    TagType.find_each { |tag_type| TagType.update_counters tag_type.id, :tags_count => tag_type.tags.count }  
  end
end
