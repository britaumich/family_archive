class AddFieldRoleToAdminUser < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :role, :integer
  end
end
