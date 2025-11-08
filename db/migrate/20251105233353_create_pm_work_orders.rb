class CreatePmWorkOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :pm_work_orders do |t|
      t.references :preventative_maintenance_contract, null: false, foreign_key: true
      t.references :work_order, null: false, foreign_key: true
      t.datetime :scheduled_for

      t.timestamps
    end
  end
end
