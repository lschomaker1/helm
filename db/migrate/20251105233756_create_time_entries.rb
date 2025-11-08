class CreateTimeEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :time_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :work_order, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at
      t.decimal :hours, precision: 5, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
