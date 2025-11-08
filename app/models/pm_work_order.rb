# app/models/pm_work_order.rb
class PmWorkOrder < ApplicationRecord
  belongs_to :preventative_maintenance_contract
  belongs_to :work_order
end