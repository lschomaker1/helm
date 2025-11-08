class CreatePurchaseOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_orders do |t|
      t.string  :number,           null: false             # FRE214000001, etc.
      t.integer :sequence_number,  null: false             # raw counter
      t.references :work_order,    null: false, foreign_key: true
      t.references :created_by,    null: false, foreign_key: { to_table: :users }
      t.string  :vendor_name
      t.decimal :total_amount, precision: 10, scale: 2
      t.string  :status, default: "open"
      t.text    :notes

      t.timestamps
    end

    add_index :purchase_orders, :number, unique: true
    add_index :purchase_orders, :sequence_number, unique: true
  end
end
