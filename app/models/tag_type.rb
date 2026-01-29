# == Schema Information
#
# Table name: tag_types
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TagType < ApplicationRecord
  has_many :tags, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
end
