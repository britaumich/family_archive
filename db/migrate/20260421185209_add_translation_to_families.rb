class AddTranslationToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :name_translations, :json, default: {}
  end
end
