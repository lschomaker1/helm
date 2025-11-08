class AddRateTypeToTimeEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :time_entries, :rate_type, :string, default: "regular", null: false
  end
end
