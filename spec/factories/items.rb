# == Schema Information
#
# Table name: items
#
#  id         :bigint           not null, primary key
#  item_type  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :item do
    item_type { 1 }
  end
end
