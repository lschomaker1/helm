# app/models/user.rb
class User < ApplicationRecord
  # If you DON'T want self-signup, you can remove :registerable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :division

  has_many :created_work_orders, class_name: "WorkOrder", foreign_key: :created_by_id
  has_many :assigned_work_orders, class_name: "WorkOrder", foreign_key: :assigned_to_id
  has_many :time_entries
  has_many :uaojt_sync_logs, dependent: :destroy

  # Rails 7 encryption – this treats the column as encrypted-at-rest
  # encrypts :uaojt_password_encrypted, deterministic: false if respond_to?(:encrypts)

  # Simple accessor so you can use user.uaojt_password in forms
  def uaojt_password
    uaojt_password_encrypted
  end

  def uaojt_password=(value)
    self.uaojt_password_encrypted = value if value.present?
  end

  # Only Freeport apprentices get the OJT integration
  def uaojt_enabled?
    is_apprentice? && division&.name.to_s.downcase == "freeport"
  end

  # Apprenticeship year fallback
  def current_apprenticeship_year
    (uaojt_apprenticeship_year || 1).clamp(1, 5)
  end

  # Full role set
  enum role: {
    technician:  "technician",
    dispatcher:  "dispatcher",
    manager:     "manager",
    admin:       "admin"
  }

  def full_name
    [first_name, last_name].compact.join(" ")
  end
end
