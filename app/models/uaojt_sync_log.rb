class UaojtSyncLog < ApplicationRecord
  belongs_to :user

  scope :recent, -> { order(ran_at: :desc) }

  def status_label
    success? ? "Success" : "Failure"
  end
end
