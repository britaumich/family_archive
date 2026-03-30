# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tag_type_id       :bigint
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
  belongs_to :tag_type, optional: true, counter_cache: true
  has_many :tagables
  has_many :items, through: :tagables

  validates :name, presence: true, uniqueness: true

  # JSON-based translations
  def name_for_locale(locale = I18n.locale)
    name_translations&.dig(locale.to_s) || name_translations&.dig('en') || name
  end

  def translated_name
    name_for_locale
  end

  def set_translation(locale, translation)
    self.name_translations ||= {}
    self.name_translations[locale.to_s] = translation
  end

  # For forms and admin interface
  def name_en
    name_translations&.dig('en') || name
  end

  def name_en=(value)
    set_translation('en', value)
    # Keep the original name field in sync with English for backward compatibility
    self.name = value
  end

  def name_ru
    name_translations&.dig('ru')
  end

  def name_ru=(value)
    set_translation('ru', value) if value.present?
  end
end
