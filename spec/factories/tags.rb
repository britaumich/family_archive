# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tag_type_id       :bigint
#
# Indexes
#
#  index_tags_on_tag_type_id  (tag_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (tag_type_id => tag_types.id)
#
FactoryBot.define do
  factory :tag do
    name { "MyString" }
  end
end
