# app/jobs/increment_apprenticeship_year_job.rb
class IncrementApprenticeshipYearJob < ApplicationJob
  queue_as :default

  def perform
    User.where(is_apprentice: true).find_each do |user|
      next unless user.uaojt_apprenticeship_year.present?
      next if user.uaojt_apprenticeship_year >= 5

      user.update!(uaojt_apprenticeship_year: user.uaojt_apprenticeship_year + 1)
    end
  end
end
