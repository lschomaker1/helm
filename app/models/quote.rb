# app/models/quote.rb
class Quote < ApplicationRecord
  belongs_to :customer
  belongs_to :division
  has_many :work_orders

  STATUSES = %w[draft sent accepted rejected].freeze

  validates :number, presence: true
  validates :status, inclusion: { in: STATUSES }
end
