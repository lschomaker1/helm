class CreateWorkOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :work_orders do |t|
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.datetime :scheduled_at
      t.datetime :completed_at
      t.references :customer, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.integer :created_by_id
      t.integer :assigned_to_id
      t.integer :quote_id

      t.timestamps
    end
  end
end
