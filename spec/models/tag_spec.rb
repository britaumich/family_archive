# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  family_id         :bigint
#  tag_type_id       :bigint
#
# Indexes
#
#  index_tags_on_family_id    (family_id)
#  index_tags_on_tag_type_id  (tag_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (tag_type_id => tag_types.id)
#
require 'rails_helper'

RSpec.describe Tag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
