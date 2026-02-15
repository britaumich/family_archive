# == Schema Information
#
# Table name: tag_types
#
#  id                :bigint           not null, primary key
#  name              :string
#  name_translations :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class TagType < ApplicationRecord
  has_many :tags
  before_destroy :ensure_no_tags
  validates :name, presence: true, uniqueness: true
  validate :at_least_one_translation_present

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
    self.name = value if value.present?
  end

  def name_ru
    name_translations&.dig('ru')
  end

  def name_ru=(value)
    set_translation('ru', value) if value.present?
  end

  private

  def at_least_one_translation_present
    if name_en.blank? && name_ru.blank?
      errors.add(:base, I18n.t('activerecord.errors.models.tag_type.at_least_one_translation_required'))
    end
  end

  def ensure_no_tags
    if tags.exists?
      throw(:abort)
    end
  end
end
