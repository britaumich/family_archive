class CreateTagables < ActiveRecord::Migration[8.1]
  def change
    create_table :tagables do |t|
      t.references :item, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
