class AddUniqueIndexToTagsName < ActiveRecord::Migration[8.1]
  class MigrationTag < ActiveRecord::Base
    self.table_name = :tags
  end

  class MigrationTagable < ActiveRecord::Base
    self.table_name = :tagables
  end

  def up
    deduplicate_tags_by_name!
    add_index :tags, :name, unique: true, name: :index_tags_on_name
  end

  def down
    remove_index :tags, name: :index_tags_on_name
  end

  private

  def deduplicate_tags_by_name!
    duplicate_names = MigrationTag
      .where.not(name: nil)
      .group(:name)
      .having('COUNT(*) > 1')
      .pluck(:name)

    duplicate_names.each do |name|
      tag_ids = MigrationTag.where(name: name).order(:id).pluck(:id)
      canonical_tag_id = tag_ids.shift
      duplicate_tag_ids = tag_ids
      next if canonical_tag_id.blank? || duplicate_tag_ids.empty?

      duplicate_tag_ids.each do |duplicate_tag_id|
        duplicate_item_ids = MigrationTagable.where(tag_id: duplicate_tag_id).pluck(:item_id)
        next if duplicate_item_ids.empty?

        existing_canonical_item_ids = MigrationTagable
          .where(tag_id: canonical_tag_id, item_id: duplicate_item_ids)
          .pluck(:item_id)

        if existing_canonical_item_ids.any?
          MigrationTagable.where(tag_id: duplicate_tag_id, item_id: existing_canonical_item_ids).delete_all
        end

        MigrationTagable.where(tag_id: duplicate_tag_id).update_all(tag_id: canonical_tag_id)
      end

      MigrationTag.where(id: duplicate_tag_ids).delete_all
    end
  end
end