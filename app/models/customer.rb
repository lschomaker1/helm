# app/models/customer.rb
class Customer < ApplicationRecord
  belongs_to :division
  has_many :work_orders
  has_many :quotes
  has_many :customer_form_templates

  validates :name, presence: true
end
