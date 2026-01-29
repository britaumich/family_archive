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
require 'rails_helper'

RSpec.describe Tag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
