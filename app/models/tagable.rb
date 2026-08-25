# == Schema Information
#
# Table name: tagables
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :bigint           not null
#  tag_id     :bigint           not null
#
# Indexes
#
#  index_tagables_on_item_id             (item_id)
#  index_tagables_on_item_id_and_tag_id  (item_id,tag_id) UNIQUE
#  index_tagables_on_tag_id              (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (tag_id => tags.id)
#
class Tagable < ApplicationRecord
  belongs_to :item
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :item_id }
end
