# == Schema Information
#
# Table name: items
#
#  id         :bigint           not null, primary key
#  caption    :string
#  item_type  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :item do
    item_type { 1 }

    after(:build) do |item|
      item.file.attach(
        io: StringIO.new('test file content'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      ) unless item.file.attached?
    end
  end
end
