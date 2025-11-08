# db/migrate/20251107000000_add_apprentice_fields_to_users.rb
class AddApprenticeFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_apprentice, :boolean, default: false, null: false
    add_column :users, :division, :string   # e.g. "freeport", "something_else"
    add_column :users, :uaojt_username, :string
    add_column :users, :uaojt_password_encrypted, :text
  end
end
