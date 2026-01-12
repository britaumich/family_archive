class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.integer :item_type

      t.timestamps
    end
  end
end
