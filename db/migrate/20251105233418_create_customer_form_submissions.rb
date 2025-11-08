class CreateCustomerFormSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_form_submissions do |t|
      t.references :customer_form_template, null: false, foreign_key: true
      t.references :work_order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :data

      t.timestamps
    end
  end
end
