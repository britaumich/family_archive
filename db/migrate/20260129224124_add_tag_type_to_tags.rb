class AddTagTypeToTags < ActiveRecord::Migration[8.1]
  def change
    add_reference :tags, :tag_type, null: true, foreign_key: true
  end
end
