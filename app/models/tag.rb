# == Schema Information
#
# Table name: tags
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json             not null
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

  # Keep name and name_translations['en'] in sync
  before_validation :sync_name_with_english_translation

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

  # Override name= to keep translations in sync
  def name=(value)
    super(value)
    set_translation('en', value) if value.present?
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
    if value.present?
      set_translation('ru', value)
    else
      self.name_translations&.delete('ru')
    end
  end

  private

  # Safety net to ensure name and name_translations['en'] stay in sync
  def sync_name_with_english_translation
    if name.present? && (name_translations.blank? || name_translations['en'] != name)
      set_translation('en', name)
    end
  end
end
