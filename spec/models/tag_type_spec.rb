# == Schema Information
#
# Table name: tag_types
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json
#  tags_count        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require 'rails_helper'

RSpec.describe TagType, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
