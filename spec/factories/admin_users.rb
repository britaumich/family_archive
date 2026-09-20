# == Schema Information
#
# Table name: admin_users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  role       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    role { :admin }

    trait :editor do
      role { :editor }
    end
  end
end
