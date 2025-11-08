class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.string :number
      t.references :customer, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2
      t.string :status
      t.text :description

      t.timestamps
    end
  end
end
