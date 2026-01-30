# == Schema Information
#
# Table name: tags
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tag_type_id :bigint
#
# Indexes
#
#  index_tags_on_tag_type_id  (tag_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (tag_type_id => tag_types.id)
#
class Tag < ApplicationRecord
  belongs_to :tag_type, optional: true
  has_many :tagables
  has_many :items, through: :tagables

  validates :name, presence: true, uniqueness: true
end
