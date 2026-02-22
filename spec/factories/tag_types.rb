# == Schema Information
#
# Table name: tag_types
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json
#  tags_count        :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :tag_type do
    name { "MyString" }
  end
end
