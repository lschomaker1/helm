# db/migrate/20251107205047_add_number_and_location_to_work_orders.rb
class AddNumberAndLocationToWorkOrders < ActiveRecord::Migration[7.1]
  def change
    # Only add :number if it doesn't already exist
    unless column_exists?(:work_orders, :number)
      add_column :work_orders, :number, :string
    end

    # Only add :location if it doesn't already exist
    unless column_exists?(:work_orders, :location)
      add_column :work_orders, :location, :string
    end
  end
end
