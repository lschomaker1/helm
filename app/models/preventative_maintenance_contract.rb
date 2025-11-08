# app/models/preventative_maintenance_contract.rb
class PreventativeMaintenanceContract < ApplicationRecord
  belongs_to :customer
  belongs_to :division

  has_many :pm_work_orders
  has_many :work_orders, through: :pm_work_orders
end


