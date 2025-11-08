class WorkOrderCall < ApplicationRecord
  belongs_to :work_order
  belongs_to :technician, class_name: "User"

  validates :sequence_number, presence: true
  validates :technician_id, uniqueness: { scope: :work_order_id }

  before_validation :assign_sequence_number, on: :create

  def call_identifier
    "#{work_order.number}-#{sequence_number}"
  end

  private

  def assign_sequence_number
    return if sequence_number.present? || work_order.blank?

    max_seq = work_order.work_order_calls.maximum(:sequence_number) || 0
    self.sequence_number = max_seq + 1
  end
end
