class CreateDivisions < ActiveRecord::Migration[7.1]
  def change
    create_table :divisions do |t|
      t.string :name

      t.timestamps
    end
  end
end
