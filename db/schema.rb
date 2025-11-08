# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_08_045444) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customer_form_submissions", force: :cascade do |t|
    t.bigint "customer_form_template_id", null: false
    t.bigint "work_order_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_form_template_id"], name: "index_customer_form_submissions_on_customer_form_template_id"
    t.index ["user_id"], name: "index_customer_form_submissions_on_user_id"
    t.index ["work_order_id"], name: "index_customer_form_submissions_on_work_order_id"
  end

  create_table "customer_form_templates", force: :cascade do |t|
    t.string "name"
    t.bigint "customer_id", null: false
    t.bigint "division_id", null: false
    t.jsonb "schema"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_form_templates_on_customer_id"
    t.index ["division_id"], name: "index_customer_form_templates_on_division_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "phone"
    t.string "email"
    t.bigint "division_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_customers_on_division_id"
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pm_work_orders", force: :cascade do |t|
    t.bigint "preventative_maintenance_contract_id", null: false
    t.bigint "work_order_id", null: false
    t.datetime "scheduled_for"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["preventative_maintenance_contract_id"], name: "index_pm_work_orders_on_preventative_maintenance_contract_id"
    t.index ["work_order_id"], name: "index_pm_work_orders_on_work_order_id"
  end

  create_table "preventative_maintenance_contracts", force: :cascade do |t|
    t.string "name"
    t.bigint "customer_id", null: false
    t.bigint "division_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "frequency"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_preventative_maintenance_contracts_on_customer_id"
    t.index ["division_id"], name: "index_preventative_maintenance_contracts_on_division_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string "number"
    t.string "vendor_name"
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "status"
    t.bigint "work_order_id", null: false
    t.bigint "division_id", null: false
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_purchase_orders_on_division_id"
    t.index ["work_order_id"], name: "index_purchase_orders_on_work_order_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.string "number"
    t.bigint "customer_id", null: false
    t.bigint "division_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "status"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_quotes_on_customer_id"
    t.index ["division_id"], name: "index_quotes_on_division_id"
  end

  create_table "time_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "work_order_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.decimal "hours", precision: 5, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rate_type", default: "regular", null: false
    t.index ["user_id"], name: "index_time_entries_on_user_id"
    t.index ["work_order_id"], name: "index_time_entries_on_work_order_id"
  end

  create_table "uaojt_sync_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "month", null: false
    t.datetime "ran_at", null: false
    t.boolean "success", default: false, null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_uaojt_sync_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "role", default: "technician", null: false
    t.bigint "division_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_apprentice", default: false, null: false
    t.string "division"
    t.string "uaojt_username"
    t.text "uaojt_password_encrypted"
    t.integer "uaojt_hours_rep_id"
    t.integer "uaojt_apprenticeship_year", default: 1, null: false
    t.date "uaojt_school_start"
    t.date "uaojt_school_end"
    t.index ["division_id"], name: "index_users_on_division_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_order_calls", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "technician_id", null: false
    t.integer "sequence_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["technician_id"], name: "index_work_order_calls_on_technician_id"
    t.index ["work_order_id", "sequence_number"], name: "index_work_order_calls_on_work_order_id_and_sequence_number", unique: true
    t.index ["work_order_id", "technician_id"], name: "index_work_order_calls_on_work_order_id_and_technician_id", unique: true
    t.index ["work_order_id"], name: "index_work_order_calls_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "status"
    t.string "priority"
    t.datetime "scheduled_at"
    t.datetime "completed_at"
    t.bigint "customer_id", null: false
    t.bigint "division_id", null: false
    t.integer "created_by_id"
    t.integer "assigned_to_id"
    t.integer "quote_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.string "location"
    t.decimal "material_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "material_markup_percent", precision: 5, scale: 2, default: "25.0"
    t.string "invoice_number"
    t.decimal "invoice_total", precision: 10, scale: 2
    t.index ["customer_id"], name: "index_work_orders_on_customer_id"
    t.index ["division_id"], name: "index_work_orders_on_division_id"
  end

  add_foreign_key "customer_form_submissions", "customer_form_templates"
  add_foreign_key "customer_form_submissions", "users"
  add_foreign_key "customer_form_submissions", "work_orders"
  add_foreign_key "customer_form_templates", "customers"
  add_foreign_key "customer_form_templates", "divisions"
  add_foreign_key "customers", "divisions"
  add_foreign_key "pm_work_orders", "preventative_maintenance_contracts"
  add_foreign_key "pm_work_orders", "work_orders"
  add_foreign_key "preventative_maintenance_contracts", "customers"
  add_foreign_key "preventative_maintenance_contracts", "divisions"
  add_foreign_key "purchase_orders", "divisions"
  add_foreign_key "purchase_orders", "work_orders"
  add_foreign_key "quotes", "customers"
  add_foreign_key "quotes", "divisions"
  add_foreign_key "time_entries", "users"
  add_foreign_key "time_entries", "work_orders"
  add_foreign_key "uaojt_sync_logs", "users"
  add_foreign_key "work_order_calls", "users", column: "technician_id"
  add_foreign_key "work_order_calls", "work_orders"
  add_foreign_key "work_orders", "customers"
  add_foreign_key "work_orders", "divisions"
end
