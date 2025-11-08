# app/models/purchase_order.rb
class PurchaseOrder < ApplicationRecord
  belongs_to :work_order, optional: true
  belongs_to :division
  belongs_to :created_by, class_name: "User"

  STATUSES = %w[draft submitted approved ordered received].freeze

  validates :number, presence: true
  validates :status, inclusion: { in: STATUSES }
end
