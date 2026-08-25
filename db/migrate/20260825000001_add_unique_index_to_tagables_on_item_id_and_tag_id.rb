class AddUniqueIndexToTagablesOnItemIdAndTagId < ActiveRecord::Migration[8.1]
  class MigrationTagable < ActiveRecord::Base
    self.table_name = :tagables
  end

  def up
    deduplicate_tagables!
    add_index :tagables, [:item_id, :tag_id], unique: true, name: :index_tagables_on_item_id_and_tag_id
  end

  def down
    remove_index :tagables, name: :index_tagables_on_item_id_and_tag_id
  end

  private

  def deduplicate_tagables!
    duplicate_pairs = MigrationTagable
      .group(:item_id, :tag_id)
      .having('COUNT(*) > 1')
      .pluck(:item_id, :tag_id)

    duplicate_pairs.each do |item_id, tag_id|
      ids_to_delete = MigrationTagable
        .where(item_id: item_id, tag_id: tag_id)
        .order(:id)
        .offset(1)
        .pluck(:id)

      MigrationTagable.where(id: ids_to_delete).delete_all if ids_to_delete.any?
    end
  end
end