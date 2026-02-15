# == Schema Information
#
# Table name: tag_types
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_en           :string
#  name_ru           :string
#  name_translations :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_tag_types_on_name_en  (name_en)
#  index_tag_types_on_name_ru  (name_ru)
#
FactoryBot.define do
  factory :tag_type do
    name { "MyString" }
  end
end
