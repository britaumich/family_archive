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
  has_many :tags
  before_destroy :ensure_no_tags
  validates :name, presence: true, uniqueness: true

  private

  def ensure_no_tags
    if tags.exists?
      throw(:abort)
    end
  end
end
