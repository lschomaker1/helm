class Message < ApplicationRecord
  belongs_to :sender,    class_name: "User"
  belongs_to :recipient, class_name: "User"

  scope :inbox_for, ->(user) { where(recipient: user).order(created_at: :desc) }
  scope :sent_by,   ->(user) { where(sender: user).order(created_at: :desc) }
end
