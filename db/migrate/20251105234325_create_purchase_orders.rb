class CreatePurchaseOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_orders do |t|
      t.string :number
      t.string :vendor_name
      t.decimal :total_amount, precision: 10, scale: 2
      t.string :status
      t.references :work_order, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.integer :created_by_id

      t.timestamps
    end
  end
end
