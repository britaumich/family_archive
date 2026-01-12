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
#  index_tagables_on_item_id  (item_id)
#  index_tagables_on_tag_id   (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (tag_id => tags.id)
#
FactoryBot.define do
  factory :tagable do
    item { nil }
    tag { nil }
  end
end
