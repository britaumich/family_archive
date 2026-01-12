# == Schema Information
#
# Table name: items
#
#  id         :bigint           not null, primary key
#  item_type  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Item < ApplicationRecord
  has_many :tagables
  has_many :tags, through: :tagables

  has_one_attached :file

  enum :item_type, [:photo, :video, :text], prefix: true
end
