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
class Item < ApplicationRecord
  has_many :tagables, dependent: :destroy
  has_many :tags, through: :tagables

  has_one_attached :file
  
  # Define thumb variants for different display sizes
  def thumb_small
    return nil unless file.attached? && file.variable?
    file.variant(resize_to_limit: [300, 150])
  end
  
  def thumb_medium
    return nil unless file.attached? && file.variable?
    file.variant(resize_to_limit: [400, 250])
  end

  enum :item_type, %i[photo video document], prefix: true

  validates :file, presence: true
  validates :item_type, presence: true
end
