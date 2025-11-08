# app/models/customer_form_template.rb
class CustomerFormTemplate < ApplicationRecord
  belongs_to :customer
  belongs_to :division
  has_many :customer_form_submissions

  validates :name, presence: true
end

