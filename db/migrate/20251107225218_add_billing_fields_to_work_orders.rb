class AddBillingFieldsToWorkOrders < ActiveRecord::Migration[7.1]
  def change
    unless(column_exists?(:work_orders, :completed_at))
      add_column :work_orders, :completed_at, :datetime
    end
    add_column :work_orders, :material_cost, :decimal, precision: 10, scale: 2, default: 0
    add_column :work_orders, :material_markup_percent, :decimal, precision: 5, scale: 2, default: 25
    add_column :work_orders, :invoice_number, :string
    add_column :work_orders, :invoice_total, :decimal, precision: 10, scale: 2
  end
end
