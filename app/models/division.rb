# app/models/division.rb
class Division < ApplicationRecord
  has_many :users
  has_many :customers
  has_many :work_orders
  has_many :preventative_maintenance_contracts
  has_many :purchase_orders
  has_many :quotes

  validates :name, presence: true, uniqueness: true
end
