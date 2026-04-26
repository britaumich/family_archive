# == Schema Information
#
# Table name: families
#
#  id                :bigint           not null, primary key
#  name              :string           not null
#  name_translations :json
#  tags_count        :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :family do
    name { "MyString" }
  end
end
