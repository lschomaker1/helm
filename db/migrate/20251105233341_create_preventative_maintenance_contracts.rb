class CreatePreventativeMaintenanceContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :preventative_maintenance_contracts do |t|
      t.string :name
      t.references :customer, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :frequency
      t.text :notes

      t.timestamps
    end
  end
end
