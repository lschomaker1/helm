class CustomerFormSubmission < ApplicationRecord
  belongs_to :customer_form_template
  belongs_to :work_order
  belongs_to :user
end