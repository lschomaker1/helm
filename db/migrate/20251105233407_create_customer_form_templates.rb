class CreateCustomerFormTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_form_templates do |t|
      t.string :name
      t.references :customer, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true
      t.jsonb :schema

      t.timestamps
    end
  end
end
