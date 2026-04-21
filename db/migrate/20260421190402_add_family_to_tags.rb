class AddFamilyToTags < ActiveRecord::Migration[8.1]
  def change
    add_reference :tags, :family, null: true, foreign_key: true
  end
end
