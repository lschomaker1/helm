class CreateWorkOrderCalls < ActiveRecord::Migration[7.1]
  def change
    create_table :work_order_calls do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :technician, null: false, foreign_key: { to_table: :users }
      t.integer :sequence_number, null: false

      t.timestamps
    end

    add_index :work_order_calls, [:work_order_id, :sequence_number], unique: true
    add_index :work_order_calls, [:work_order_id, :technician_id], unique: true
  end
end
