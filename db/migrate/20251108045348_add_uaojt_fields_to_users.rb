class AddUaojtFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :uaojt_hours_rep_id, :integer
    add_column :users, :uaojt_apprenticeship_year, :integer, default: 1, null: false
    add_column :users, :uaojt_school_start, :date
    add_column :users, :uaojt_school_end, :date
  end
end
