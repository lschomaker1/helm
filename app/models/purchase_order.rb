class PurchaseOrder < ApplicationRecord
  belongs_to :work_order
  belongs_to :created_by, class_name: "User"

  before_validation :assign_numbers, on: :create

  validates :number, presence: true, uniqueness: true
  validates :sequence_number, presence: true, uniqueness: true

  private

  def assign_numbers
    return if sequence_number.present? && number.present?

    self.sequence_number ||= (PurchaseOrder.maximum(:sequence_number) || 0) + 1
    self.number ||= format("FRE214%06d", sequence_number)
  end
end
